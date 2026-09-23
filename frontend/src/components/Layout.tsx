import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from '../context/useAuth'

export function Layout() {
  const { email, logout } = useAuth()

  return (
    <div className="app-shell">
      <header className="app-header">
        <span className="brand">ACME Salary Management</span>
        <nav>
          <NavLink to="/" end>
            Dashboard
          </NavLink>
          <NavLink to="/employees">Employees</NavLink>
          <NavLink to="/employees/new">Add Employee</NavLink>
        </nav>
        <div className="user-menu">
          <span>{email}</span>
          <button type="button" onClick={logout}>
            Log out
          </button>
        </div>
      </header>
      <main className="app-main">
        <Outlet />
      </main>
    </div>
  )
}
