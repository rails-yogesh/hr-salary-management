import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { ApiError } from '../api/client'
import * as endpoints from '../api/endpoints'
import { AuthProvider } from '../context/AuthContext'
import { LoginPage } from './LoginPage'

function renderLoginPage() {
  return render(
    <AuthProvider>
      <MemoryRouter initialEntries={['/login']}>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/" element={<div>Dashboard Home</div>} />
        </Routes>
      </MemoryRouter>
    </AuthProvider>,
  )
}

describe('LoginPage', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('logs in and redirects to the dashboard on success', async () => {
    vi.spyOn(endpoints, 'login').mockResolvedValue({ token: 'abc123', email: 'hr@acme.test' })
    const user = userEvent.setup()
    renderLoginPage()

    await user.type(screen.getByLabelText(/email/i), 'hr@acme.test')
    await user.type(screen.getByLabelText(/password/i), 'correct-horse-battery-staple')
    await user.click(screen.getByRole('button', { name: /sign in/i }))

    await waitFor(() => expect(screen.getByText('Dashboard Home')).toBeInTheDocument())
    expect(endpoints.login).toHaveBeenCalledWith('hr@acme.test', 'correct-horse-battery-staple')
    expect(localStorage.getItem('acme_salary_token')).toBe('abc123')
  })

  it('shows an error message and stays on the page for invalid credentials', async () => {
    vi.spyOn(endpoints, 'login').mockRejectedValue(new ApiError(401, 'invalid email or password'))
    const user = userEvent.setup()
    renderLoginPage()

    await user.type(screen.getByLabelText(/email/i), 'hr@acme.test')
    await user.type(screen.getByLabelText(/password/i), 'wrong-password')
    await user.click(screen.getByRole('button', { name: /sign in/i }))

    expect(await screen.findByRole('alert')).toHaveTextContent('invalid email or password')
    expect(screen.queryByText('Dashboard Home')).not.toBeInTheDocument()
    expect(localStorage.getItem('acme_salary_token')).toBeNull()
  })
})
