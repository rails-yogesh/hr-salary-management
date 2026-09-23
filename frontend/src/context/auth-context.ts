import { createContext } from 'react'

export interface AuthContextValue {
  isAuthenticated: boolean
  email: string | null
  login: (email: string, password: string) => Promise<void>
  logout: () => void
}

export const AuthContext = createContext<AuthContextValue | undefined>(undefined)
