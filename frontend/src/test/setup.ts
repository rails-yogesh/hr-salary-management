import { cleanup } from '@testing-library/react'
import '@testing-library/jest-dom/vitest'
import { afterEach, vi } from 'vitest'

// Without Vitest's `globals: true`, @testing-library/react's automatic
// cleanup (which relies on a global `afterEach`) never registers — so DOM
// from one test leaks into the next. Wire it up explicitly instead of
// turning on globals just for this.
afterEach(() => {
  cleanup()
})

// jsdom has no layout engine and no ResizeObserver, which recharts'
// ResponsiveContainer needs to measure its container. Without this stub,
// every chart-rendering test logs noisy warnings (harmless, but chart pixel
// layout isn't something a unit test should be asserting on anyway — see
// DashboardPage tests, which check the data/formatting instead).
class ResizeObserverStub {
  observe() {}
  unobserve() {}
  disconnect() {}
}
vi.stubGlobal('ResizeObserver', ResizeObserverStub)
