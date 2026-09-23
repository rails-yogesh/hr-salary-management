import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { apiRequest, ApiError, clearToken, getToken, setToken } from './client'

describe('api client', () => {
  beforeEach(() => {
    localStorage.clear()
    vi.stubGlobal('fetch', vi.fn())
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  describe('token storage', () => {
    it('persists and clears the token', () => {
      expect(getToken()).toBeNull()

      setToken('abc123')
      expect(getToken()).toBe('abc123')

      clearToken()
      expect(getToken()).toBeNull()
    })
  })

  describe('apiRequest', () => {
    it('attaches the bearer token when one is stored', async () => {
      setToken('my-token')
      vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({ ok: true }), { status: 200 }))

      await apiRequest('/employees')

      const [, init] = vi.mocked(fetch).mock.calls[0]
      const headers = init?.headers as Record<string, string> | undefined
      expect(headers?.Authorization).toBe('Bearer my-token')
    })

    it('omits the Authorization header when there is no token', async () => {
      vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({ ok: true }), { status: 200 }))

      await apiRequest('/health')

      const [, init] = vi.mocked(fetch).mock.calls[0]
      const headers = init?.headers as Record<string, string> | undefined
      expect(headers?.Authorization).toBeUndefined()
    })

    it('serializes query params, skipping blank/undefined values', async () => {
      vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({}), { status: 200 }))

      await apiRequest('/employees', { params: { q: 'ada', page: 2, department_id: undefined, country_id: '' } })

      const [url] = vi.mocked(fetch).mock.calls[0]
      const parsed = new URL(url as string)
      expect(parsed.searchParams.get('q')).toBe('ada')
      expect(parsed.searchParams.get('page')).toBe('2')
      expect(parsed.searchParams.has('department_id')).toBe(false)
      expect(parsed.searchParams.has('country_id')).toBe(false)
    })

    it('returns parsed JSON on success', async () => {
      vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({ headcount: 42 }), { status: 200 }))

      const result = await apiRequest<{ headcount: number }>('/dashboard/summary')

      expect(result).toEqual({ headcount: 42 })
    })

    it('throws an ApiError with the server message on failure', async () => {
      vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({ error: 'invalid email or password' }), { status: 401 }))

      await expect(apiRequest('/login', { method: 'POST' })).rejects.toMatchObject({
        message: 'invalid email or password',
        status: 401,
      })
    })

    it('joins an array of validation errors into one message', async () => {
      vi.mocked(fetch).mockResolvedValue(
        new Response(JSON.stringify({ error: ["Work email can't be blank", 'Amount cents must be greater than 0'] }), { status: 422 }),
      )

      await expect(apiRequest('/employees', { method: 'POST' })).rejects.toThrow(
        "Work email can't be blank, Amount cents must be greater than 0",
      )
    })

    it('falls back to a generic message when the response has no error body', async () => {
      vi.mocked(fetch).mockResolvedValue(new Response('', { status: 500 }))

      await expect(apiRequest('/employees')).rejects.toBeInstanceOf(ApiError)
    })
  })
})
