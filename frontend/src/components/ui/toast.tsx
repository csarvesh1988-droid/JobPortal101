'use client'

import { createContext, useContext, useState, useCallback, ReactNode } from 'react'
import { cn } from '@/lib/utils'

interface Toast {
  id: string
  title?: string
  message: string
  type?: 'success' | 'error' | 'warning' | 'info'
  duration?: number
}

interface ToastContextValue {
  toasts: Toast[]
  addToast: (toast: Omit<Toast, 'id'>) => void
  removeToast: (id: string) => void
}

const ToastContext = createContext<ToastContextValue | undefined>(undefined)

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([])

  const addToast = useCallback((toast: Omit<Toast, 'id'>) => {
    const id = Math.random().toString(36).substring(2)
    const newToast = { ...toast, id }
    
    setToasts(prev => [...prev, newToast])
    
    // Auto remove after duration
    const duration = toast.duration || 5000
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id))
    }, duration)
  }, [])

  const removeToast = useCallback((id: string) => {
    setToasts(prev => prev.filter(t => t.id !== id))
  }, [])

  return (
    <ToastContext.Provider value={{ toasts, addToast, removeToast }}>
      {children}
    </ToastContext.Provider>
  )
}

export function useToast() {
  const context = useContext(ToastContext)
  if (!context) {
    throw new Error('useToast must be used within ToastProvider')
  }
  return context
}

export function Toaster() {
  const { toasts, removeToast } = useToast()

  return (
    <div className="fixed bottom-0 right-0 z-50 p-4 space-y-2">
      {toasts.map(toast => (
        <ToastComponent
          key={toast.id}
          toast={toast}
          onRemove={() => removeToast(toast.id)}
        />
      ))}
    </div>
  )
}

function ToastComponent({ 
  toast, 
  onRemove 
}: { 
  toast: Toast
  onRemove: () => void 
}) {
  const typeStyles = {
    success: 'bg-green-50 border-green-200 text-green-800',
    error: 'bg-red-50 border-red-200 text-red-800',
    warning: 'bg-yellow-50 border-yellow-200 text-yellow-800',
    info: 'bg-blue-50 border-blue-200 text-blue-800'
  }

  const type = toast.type || 'info'

  return (
    <div className={cn(
      'max-w-sm w-full shadow-lg rounded-lg border p-4 transform transition-all duration-300 ease-in-out',
      typeStyles[type]
    )}>
      <div className="flex items-start">
        <div className="flex-1">
          {toast.title && (
            <p className="font-medium mb-1">{toast.title}</p>
          )}
          <p className="text-sm">{toast.message}</p>
        </div>
        
        <button
          onClick={onRemove}
          className="ml-4 text-gray-400 hover:text-gray-600 focus:outline-none"
        >
          <span className="sr-only">Close</span>
          <svg className="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
          </svg>
        </button>
      </div>
    </div>
  )
}