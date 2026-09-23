import { cleanup } from '@testing-library/react'
import '@testing-library/jest-dom/vitest'
import { afterEach } from 'vitest'

// Without Vitest's `globals: true`, @testing-library/react's automatic
// cleanup (which relies on a global `afterEach`) never registers — so DOM
// from one test leaks into the next. Wire it up explicitly instead of
// turning on globals just for this.
afterEach(() => {
  cleanup()
})
