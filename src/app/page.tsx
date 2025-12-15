'use client'

import { useRouter } from 'next/navigation'
import { useCallback } from 'react'

export default function Home() {
  const router = useRouter()

  const handleStart = useCallback(() => {
    const id = crypto.randomUUID()
    router.push(`/workspace/${id}`)
  }, [router])

  return (
    <main className="flex min-h-screen items-center justify-center bg-gray-50">
      <button
        onClick={handleStart}
        className="rounded bg-blue-600 px-6 py-3 text-lg font-semibold text-white shadow transition hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-offset-2"
      >
        Start Workshop
      </button>
    </main>
  )
}
