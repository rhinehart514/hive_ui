'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';
import { User } from 'firebase/auth';
import { useRouter } from 'next/navigation';
import { 
  onAuthStateChange, 
  getUserProfile, 
  UserProfile, 
  logOut,
  getRedirectPath,
  shouldRedirectFromAuth,
  AuthState
} from '../lib/auth';

interface AuthContextType extends AuthState {
  refreshProfile: () => Promise<void>;
  signOut: () => Promise<void>;
  redirectToCorrectPage: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  const refreshProfile = async () => {
    if (user) {
      try {
        const userProfile = await getUserProfile(user.uid);
        setProfile(userProfile);
      } catch (error) {
        console.error('Error fetching user profile:', error);
        setProfile(null);
      }
    } else {
      setProfile(null);
    }
  };

  const redirectToCorrectPage = () => {
    const correctPath = getRedirectPath(user, profile);
    if (correctPath !== window.location.pathname) {
      router.push(correctPath);
    }
  };

  useEffect(() => {
    const unsubscribe = onAuthStateChange(async (firebaseUser) => {
      setUser(firebaseUser);
      setLoading(true);

      if (firebaseUser) {
        try {
          const userProfile = await getUserProfile(firebaseUser.uid);
          setProfile(userProfile);
        } catch (error) {
          console.error('Error fetching user profile:', error);
          setProfile(null);
        }
      } else {
        setProfile(null);
      }

      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  // Auto-redirect based on auth state
  useEffect(() => {
    if (!loading) {
      const currentPath = window.location.pathname;
      const correctPath = getRedirectPath(user, profile);
      
      // Define public routes that don't require auth
      const publicRoutes = [
        '/',
        '/design-system',
        '/auth',
      ];
      
      const isPublicRoute = publicRoutes.some(route => 
        currentPath === route || currentPath.startsWith(route + '/')
      );
      
      // Handle redirects for auth pages
      const isAuthPage = currentPath.startsWith('/auth');
      const shouldRedirect = shouldRedirectFromAuth(user, profile);
      
      if (isAuthPage && shouldRedirect) {
        router.push('/feed');
      } else if (!isPublicRoute && correctPath !== currentPath && !currentPath.startsWith('/auth')) {
        router.push(correctPath);
      }
    }
  }, [user, profile, loading, router]);

  const signOut = async () => {
    try {
      await logOut();
      router.push('/');
    } catch (error) {
      console.error('Error signing out:', error);
      throw error;
    }
  };

  const value: AuthContextType = {
    user,
    profile,
    loading,
    isAuthenticated: !!user,
    refreshProfile,
    signOut,
    redirectToCorrectPage,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
} 