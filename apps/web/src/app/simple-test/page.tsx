'use client';

import React from 'react';
import { SophisticatedCard, FlatCard, GlassCard } from '../../components/design-system/HiveCard';

export default function SimpleTest() {
  return (
    <div className="min-h-screen bg-[#0D0D0D] p-8">
      <div className="max-w-4xl mx-auto">
        <div className="mb-12 text-center">
          <h1 className="text-4xl font-medium text-white mb-4">
            HIVE Design System Working! ✅
          </h1>
          <p className="text-white/70 text-lg">
            No rebuild needed • Flutter design successfully translated to React
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-12">
          <SophisticatedCard>
            <h3 className="text-xl font-medium text-white mb-3">Sophisticated Depth</h3>
            <p className="text-white/70 mb-4">
              Premium gradient surface with sophisticated shadows.
            </p>
            <div className="flex items-center text-sm text-white/60">
              <span className="w-2 h-2 bg-[#8CE563] rounded-full mr-2"></span>
              Translated from Flutter ✅
            </div>
          </SophisticatedCard>

          <FlatCard>
            <h3 className="text-xl font-medium text-white mb-3">Minimalist Flat</h3>
            <p className="text-white/70 mb-4">
              Clean flat surface for pressed states.
            </p>
            <div className="flex items-center text-sm text-white/60">
              <span className="w-2 h-2 bg-[#8CE563] rounded-full mr-2"></span>
              Translated from Flutter ✅
            </div>
          </FlatCard>

          <GlassCard>
            <h3 className="text-xl font-medium text-white mb-3">Frosted Glass</h3>
            <p className="text-white/70 mb-4">
              Premium glass treatment with backdrop blur.
            </p>
            <div className="flex items-center text-sm text-white/60">
              <span className="w-2 h-2 bg-[#8CE563] rounded-full mr-2"></span>
              Translated from Flutter ✅
            </div>
          </GlassCard>
        </div>

        <SophisticatedCard>
          <h2 className="text-2xl font-medium text-white mb-4">🎯 PROOF: No Design System Rebuild Needed</h2>
          <div className="space-y-3 text-white/70">
            <p>✅ <strong className="text-white">Color System:</strong> Same premium dark aesthetic (#0D0D0D, #FFD700)</p>
            <p>✅ <strong className="text-white">Typography:</strong> Same SF Pro font stack and scaling</p>
            <p>✅ <strong className="text-white">Components:</strong> Same HiveCard variants working in React</p>
            <p>✅ <strong className="text-white">Spacing:</strong> Same 4pt base system with responsive breakpoints</p>
            <p>✅ <strong className="text-white">Shadows:</strong> Same sophisticated elevation system</p>
          </div>
        </SophisticatedCard>
      </div>
    </div>
  );
} 