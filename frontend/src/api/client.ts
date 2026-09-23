const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? '/api/v1'
const TOKEN_STORAGE_KEY = 'acme_salary_token'

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_STORAGE_KEY)
}

export function setToken(token: string): void {
  localStorage.setItem(TOKEN_STORAGE_KEY, token)
}

export function clearToken(): void {
  localStorage.removeItem(TOKEN_STORAGE_KEY)
}

export class ApiError extends Error {
  status: number

  constructor(status: number, message: string) {
    super(message)
    this.name = 'ApiError'
    this.status = status
  }
}

interface RequestOptions {
  method?: string
  params?: Record<string, unknown>
  body?: unknown
}

function buildUrl(path: string, params?: RequestOptions['params']): string {
  const url = new URL(`${API_BASE_URL}${path}`, window.location.origin)
  if (params) {
    for (const [key, value] of Object.entries(params)) {
      if (value !== undefined && value !== null && value !== '') url.searchParams.set(key, String(value))
    }
  }
  return url.toString()
}

function extractErrorMessage(data: unknown, status: number): string {
  if (data && typeof data === 'object' && 'error' in data) {
    const error = (data as { error: unknown }).error
    if (Array.isArray(error)) return error.join(', ')
    if (typeof error === 'string') return error
  }
  return `Request failed with status ${status}`
}

export async function apiRequest<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const token = getToken()
  const headers: Record<string, string> = { 'Content-Type': 'application/json' }
  if (token) headers.Authorization = `Bearer ${token}`

  const response = await fetch(buildUrl(path, options.params), {
    method: options.method ?? 'GET',
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  })

  if (response.status === 204) return undefined as T

  const data = await response.json().catch(() => null)

  if (!response.ok) {
    throw new ApiError(response.status, extractErrorMessage(data, response.status))
  }

  return data as T
}
