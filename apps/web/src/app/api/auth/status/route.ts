import { NextRequest, NextResponse } from 'next/server';
import { cookies } from 'next/headers';

export async function GET(request: NextRequest) {
  try {
    const cookieStore = cookies();
    const authToken = cookieStore.get('firebase-auth-token')?.value || 
                     cookieStore.get('__session')?.value;

    if (!authToken) {
      return NextResponse.json({
        authenticated: false,
        user: null
      });
    }

    // In a production environment, you would verify the token with Firebase Admin SDK
    // For now, we'll return basic information
    return NextResponse.json({
      authenticated: true,
      token: authToken.substring(0, 10) + '...' // Don't expose full token
    });
  } catch (error) {
    console.error('Auth status check error:', error);
    return NextResponse.json({
      authenticated: false,
      error: 'Failed to check authentication status'
    }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const { token } = await request.json();
    
    if (!token) {
      return NextResponse.json({
        error: 'Token is required'
      }, { status: 400 });
    }

    // Set the authentication cookie
    const response = NextResponse.json({
      success: true,
      message: 'Authentication token set'
    });

    response.cookies.set('firebase-auth-token', token, {
      httpOnly: false, // Needs to be accessible by client-side JavaScript
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 60 * 60 * 24, // 24 hours
      path: '/'
    });

    return response;
  } catch (error) {
    console.error('Token setting error:', error);
    return NextResponse.json({
      error: 'Failed to set authentication token'
    }, { status: 500 });
  }
}

export async function DELETE() {
  try {
    const response = NextResponse.json({
      success: true,
      message: 'Authentication cleared'
    });

    // Clear the authentication cookie
    response.cookies.set('firebase-auth-token', '', {
      httpOnly: false,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 0,
      path: '/'
    });

    response.cookies.set('__session', '', {
      httpOnly: false,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 0,
      path: '/'
    });

    return response;
  } catch (error) {
    console.error('Auth clear error:', error);
    return NextResponse.json({
      error: 'Failed to clear authentication'
    }, { status: 500 });
  }
} 