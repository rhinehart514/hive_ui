import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
  sendEmailVerification,
  sendPasswordResetEmail,
  User,
  onAuthStateChanged,
  AuthError
} from 'firebase/auth';
import { doc, setDoc, getDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from './firebase';

// Types
export interface UserProfile {
  uid: string;
  email: string;
  fullName: string;
  username: string;
  major: string;
  academicYear: string;
  residentialStatus: string;
  school: string;
  emailVerified: boolean;
  campusVerified: boolean;
  onboardingCompleted: boolean;
  tutorialCompleted: boolean;
  createdAt: any;
  lastLogin: any;
}

export interface SignUpData {
  email: string;
  password: string;
  fullName: string;
  major: string;
  academicYear: string;
  residentialStatus: string;
}

export interface AuthState {
  user: User | null;
  profile: UserProfile | null;
  loading: boolean;
  isAuthenticated: boolean;
}

// Session Management
export function setAuthCookie(token: string) {
  if (typeof document !== 'undefined') {
    document.cookie = `firebase-auth-token=${token}; path=/; max-age=86400; secure; samesite=strict`;
  }
}

export function clearAuthCookie() {
  if (typeof document !== 'undefined') {
    document.cookie = 'firebase-auth-token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
  }
}

export async function getAuthToken(): Promise<string | null> {
  if (auth.currentUser) {
    try {
      return await auth.currentUser.getIdToken();
    } catch (error) {
      console.error('Error getting auth token:', error);
      return null;
    }
  }
  return null;
}

// Email validation
const VALID_EDU_DOMAINS = [
  'buffalo.edu',
  'student.buffalo.edu',
  'alumni.buffalo.edu'
];

export function isValidEduEmail(email: string): boolean {
  if (!email.includes('@')) return false;
  
  const domain = email.split('@')[1].toLowerCase();
  return VALID_EDU_DOMAINS.includes(domain);
}

export function validateEmail(email: string): string | null {
  if (!email) return 'Email is required';
  
  if (!isValidEduEmail(email)) {
    return 'Please use your .edu email address';
  }
  
  return null;
}

export function validatePassword(password: string): string | null {
  if (!password) return 'Password is required';
  if (password.length < 8) return 'Password must be at least 8 characters';
  return null;
}

// Username generation
export function generateUsername(fullName: string): string {
  const nameParts = fullName.toLowerCase().trim().split(' ');
  if (nameParts.length >= 2) {
    return `${nameParts[0]}.${nameParts[1]}`;
  }
  return nameParts[0] || 'user';
}

// Authentication functions
export async function signUp(signUpData: SignUpData): Promise<{ user: User; profile: UserProfile }> {
  const { email, password, fullName, major, academicYear, residentialStatus } = signUpData;
  
  // Validate email
  const emailError = validateEmail(email);
  if (emailError) throw new Error(emailError);
  
  // Validate password
  const passwordError = validatePassword(password);
  if (passwordError) throw new Error(passwordError);
  
  try {
    // Create Firebase auth user
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;
    
    // Generate unique username
    const baseUsername = generateUsername(fullName);
    const username = await generateUniqueUsername(baseUsername);
    
    // Create user profile document
    const profile: UserProfile = {
      uid: user.uid,
      email: user.email!,
      fullName,
      username,
      major,
      academicYear,
      residentialStatus,
      school: 'University at Buffalo',
      emailVerified: false,
      campusVerified: true, // .edu domain verification
      onboardingCompleted: false,
      tutorialCompleted: false,
      createdAt: serverTimestamp(),
      lastLogin: serverTimestamp(),
    };
    
    // Save to Firestore
    await setDoc(doc(db, 'users', user.uid), profile);
    
    // Set auth cookie for middleware
    const token = await user.getIdToken();
    setAuthCookie(token);
    
    // Send email verification
    await sendEmailVerification(user);
    
    return { user, profile };
  } catch (error) {
    const authError = error as AuthError;
    throw new Error(getAuthErrorMessage(authError.code));
  }
}

export async function signIn(email: string, password: string): Promise<User> {
  try {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    
    // Set auth cookie for middleware
    const token = await userCredential.user.getIdToken();
    setAuthCookie(token);
    
    // Update last login
    await updateDoc(doc(db, 'users', userCredential.user.uid), {
      lastLogin: serverTimestamp()
    });
    
    return userCredential.user;
  } catch (error) {
    const authError = error as AuthError;
    throw new Error(getAuthErrorMessage(authError.code));
  }
}

export async function logOut(): Promise<void> {
  try {
    clearAuthCookie();
    await signOut(auth);
  } catch (error) {
    const authError = error as AuthError;
    throw new Error(getAuthErrorMessage(authError.code));
  }
}

export async function resetPassword(email: string): Promise<void> {
  try {
    await sendPasswordResetEmail(auth, email);
  } catch (error) {
    const authError = error as AuthError;
    throw new Error(getAuthErrorMessage(authError.code));
  }
}

export async function resendEmailVerification(): Promise<void> {
  if (auth.currentUser) {
    try {
      await sendEmailVerification(auth.currentUser);
    } catch (error) {
      const authError = error as AuthError;
      throw new Error(getAuthErrorMessage(authError.code));
    }
  } else {
    throw new Error('No user signed in');
  }
}

// Helper functions
async function generateUniqueUsername(baseUsername: string): Promise<string> {
  let username = baseUsername;
  let counter = 1;
  
  while (await isUsernameTaken(username)) {
    username = `${baseUsername}${counter}`;
    counter++;
  }
  
  return username;
}

async function isUsernameTaken(username: string): Promise<boolean> {
  // This is a simplified check - in production you'd want a more efficient approach
  // like a dedicated usernames collection or cloud function
  return false; // For now, assume usernames are unique
}

export async function getUserProfile(uid: string): Promise<UserProfile | null> {
  try {
    const docSnap = await getDoc(doc(db, 'users', uid));
    if (docSnap.exists()) {
      return docSnap.data() as UserProfile;
    }
    return null;
  } catch (error) {
    console.error('Error fetching user profile:', error);
    return null;
  }
}

export async function updateUserProfile(uid: string, updates: Partial<UserProfile>): Promise<void> {
  try {
    await updateDoc(doc(db, 'users', uid), updates);
  } catch (error) {
    console.error('Error updating user profile:', error);
    throw new Error('Failed to update profile');
  }
}

function getAuthErrorMessage(code: string): string {
  switch (code) {
    case 'auth/user-not-found':
    case 'auth/wrong-password':
    case 'auth/invalid-credential':
      return 'Invalid email or password. Please try again.';
    case 'auth/email-already-in-use':
      return 'An account with this email already exists.';
    case 'auth/weak-password':
      return 'Password is too weak. Please choose a stronger password.';
    case 'auth/invalid-email':
      return 'Please enter a valid email address.';
    case 'auth/too-many-requests':
      return 'Too many failed attempts. Please try again later.';
    case 'auth/network-request-failed':
      return 'Network error. Please check your connection and try again.';
    default:
      return 'An unexpected error occurred. Please try again.';
  }
}

export function onAuthStateChange(callback: (user: User | null) => void) {
  return onAuthStateChanged(auth, async (user) => {
    if (user) {
      // Refresh token and set cookie
      try {
        const token = await user.getIdToken(true);
        setAuthCookie(token);
      } catch (error) {
        console.error('Error refreshing token:', error);
      }
    } else {
      clearAuthCookie();
    }
    callback(user);
  });
}

// Navigation helpers
export function getRedirectPath(user: User | null, profile: UserProfile | null): string {
  if (!user) return '/auth/signin';
  
  if (!user.emailVerified) return '/auth/verify-email';
  
  if (!profile) return '/auth/profile-setup';
  
  if (!profile.onboardingCompleted) return '/auth/profile-setup';
  
  if (!profile.tutorialCompleted) return '/auth/tutorial';
  
  return '/feed';
}

export function shouldRedirectFromAuth(user: User | null, profile: UserProfile | null): boolean {
  return !!(user && user.emailVerified && profile?.onboardingCompleted);
} 