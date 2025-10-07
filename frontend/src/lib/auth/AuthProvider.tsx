'use client'

import { createContext, useContext, useState, useEffect, ReactNode } from 'react'
import { User } from '@/lib/types'
import { api } from '@/lib/api/client'

interface AuthContextValue {
  user: User | null
  loading: boolean
  login: (email: string, password: string) => Promise<void>
  register: (data: any) => Promise<void>
  logout: () => void
  refreshUser: () => Promise<void>
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  // Check for existing auth on mount
  useEffect(() => {
    checkAuth()
  }, [])

  const checkAuth = async () => {
    try {
      const token = localStorage.getItem('auth-token')
      if (!token) {
        setLoading(false)
        return
      }

      // Verify token and get user data
      const response = await api.get('/api/auth/me')
      if (response.success && response.data) {
        setUser(response.data)
      } else {
        // Invalid token
        localStorage.removeItem('auth-token')
      }
    } catch (error) {
      // Token invalid or expired
      localStorage.removeItem('auth-token')
    } finally {
      setLoading(false)
    }
  }

  const login = async (email: string, password: string) => {
    try {
      const response = await api.post('/api/auth/login', { email, password })
      
      if (response.success && response.data) {
        const { token, user: userData } = response.data
        
        // Store token
        localStorage.setItem('auth-token', token)
        
        // Set user
        setUser(userData)
        
        return response
      } else {
        throw new Error(response.error || 'Login failed')
      }
    } catch (error) {
      console.error('Login error:', error)
      throw error
    }
  }

  const register = async (data: any) => {
    try {
      const response = await api.post('/api/auth/register', data)
      
      if (response.success && response.data) {
        const { token, user: userData } = response.data
        
        // Store token
        localStorage.setItem('auth-token', token)
        
        // Set user  
        setUser(userData)
        
        return response
      } else {
        throw new Error(response.error || 'Registration failed')
      }
    } catch (error) {
      console.error('Registration error:', error)
      throw error
    }
  }

  const logout = () => {
    localStorage.removeItem('auth-token')
    setUser(null)
    
    // Call logout endpoint to invalidate server-side session
    api.post('/api/auth/logout').catch(() => {
      // Ignore errors on logout
    })
  }

  const refreshUser = async () => {
    try {
      const response = await api.get('/api/auth/me')
      if (response.success && response.data) {
        setUser(response.data)
      }
    } catch (error) {
      console.error('Failed to refresh user:', error)
    }
  }

  return (
    <AuthContext.Provider value={{
      user,
      loading,
      login,
      register,
      logout,
      refreshUser
    }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return context
}