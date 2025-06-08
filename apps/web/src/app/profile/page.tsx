'use client';

import React from 'react';
import { HiveCard, HiveCardContent, HiveCardHeader, HiveCardTitle } from '@/components/ui/card';
import { UserProfile } from '@/components/patterns/UserProfile';
import { AuthGuard } from '@/components/auth/AuthGuard';

export default function ProfilePage() {
  return (
    <AuthGuard>
      <div className="min-h-screen bg-background text-foreground p-4 sm:p-6 md:p-8">
        <div className="max-w-4xl mx-auto space-y-8">
          <header>
            <h1 className="text-3xl font-bold text-primary">Your Profile</h1>
            <p className="text-muted-foreground">
              Manage your HIVE identity and settings.
            </p>
          </header>

          <UserProfile />

          <HiveCard>
            <HiveCardHeader>
              <HiveCardTitle>Settings</HiveCardTitle>
            </HiveCardHeader>
            <HiveCardContent>
              <p>General user settings will go here.</p>
            </HiveCardContent>
          </HiveCard>
        </div>
      </div>
    </AuthGuard>
  );
} 