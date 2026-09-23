import { useCallback, useState, type ReactNode } from 'react'
import { clearToken, getToken, setToken as persistToken } from '../api/client'
import { login as loginRequest } from '../api/endpoints'
import { AuthContext } from './auth-context'

const EMAIL_STORAGE_KEY = 'acme_salary_email'

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setTokenState] = useState<string | null>(() => getToken())
  const [email, setEmail] = useState<string | null>(() => localStorage.getItem(EMAIL_STORAGE_KEY))

  const login = useCallback(async (loginEmail: string, password: string) => {
    const result = await loginRequest(loginEmail, password)
    persistToken(result.token)
    localStorage.setItem(EMAIL_STORAGE_KEY, result.email)
    setTokenState(result.token)
    setEmail(result.email)
  }, [])

  const logout = useCallback(() => {
    clearToken()
    localStorage.removeItem(EMAIL_STORAGE_KEY)
    setTokenState(null)
    setEmail(null)
  }, [])

  return (
    <AuthContext.Provider value={{ isAuthenticated: Boolean(token), email, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}
