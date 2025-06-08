'use client'

export default function ColorTestPage() {
  return (
    <div 
      className="min-h-screen p-8"
      style={{ 
        backgroundColor: 'var(--hive-canvas)',
        color: 'var(--hive-text-primary)'
      }}
    >
      <div className="max-w-4xl mx-auto space-y-8">
        
        <div className="space-y-4">
          <h1 
            className="text-4xl font-bold"
            style={{ color: 'var(--hive-gold)' }}
          >
            HIVE Color System Debug Test
          </h1>
          <p style={{ color: 'var(--hive-text-secondary)' }}>
            Testing CSS variables and Tailwind classes
          </p>
        </div>

        {/* Direct CSS Variables Test */}
        <section className="space-y-4">
          <h2 
            className="text-2xl font-semibold"
            style={{ color: 'var(--hive-gold)' }}
          >
            Direct CSS Variables
          </h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div 
              className="p-4 rounded-lg text-center"
              style={{ 
                backgroundColor: 'var(--hive-surface)',
                color: 'var(--hive-text-primary)'
              }}
            >
              <div className="text-sm font-medium">Surface</div>
              <div className="text-xs opacity-70">#131313</div>
            </div>
            <div 
              className="p-4 rounded-lg text-center"
              style={{ 
                backgroundColor: 'var(--hive-gold)',
                color: 'var(--hive-canvas)'
              }}
            >
              <div className="text-sm font-medium">Gold</div>
              <div className="text-xs opacity-70">#FFD700</div>
            </div>
            <div 
              className="p-4 rounded-lg text-center"
              style={{ 
                backgroundColor: 'var(--hive-success)',
                color: 'var(--hive-canvas)'
              }}
            >
              <div className="text-sm font-medium">Success</div>
              <div className="text-xs opacity-70">#8CE563</div>
            </div>
            <div 
              className="p-4 rounded-lg text-center"
              style={{ 
                backgroundColor: 'var(--hive-error)',
                color: 'var(--hive-text-primary)'
              }}
            >
              <div className="text-sm font-medium">Error</div>
              <div className="text-xs opacity-70">#FF3B30</div>
            </div>
          </div>
        </section>

        {/* Tailwind Classes Test */}
        <section className="space-y-4">
          <h2 className="text-2xl font-semibold text-primary">
            Tailwind Classes Test
          </h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="p-4 bg-card text-card-foreground rounded-lg text-center">
              <div className="text-sm font-medium">Card</div>
              <div className="text-xs text-muted-foreground">bg-card</div>
            </div>
            <div className="p-4 bg-primary text-primary-foreground rounded-lg text-center">
              <div className="text-sm font-medium">Primary</div>
              <div className="text-xs opacity-70">bg-primary</div>
            </div>
            <div className="p-4 bg-secondary text-secondary-foreground rounded-lg text-center">
              <div className="text-sm font-medium">Secondary</div>
              <div className="text-xs text-muted-foreground">bg-secondary</div>
            </div>
            <div className="p-4 bg-destructive text-destructive-foreground rounded-lg text-center">
              <div className="text-sm font-medium">Destructive</div>
              <div className="text-xs opacity-70">bg-destructive</div>
            </div>
          </div>
        </section>

        {/* HIVE Direct Classes Test */}
        <section className="space-y-4">
          <h2 className="text-2xl font-semibold text-hive-gold">
            HIVE Direct Classes
          </h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="p-4 bg-hive-surface text-hive-text-primary rounded-lg text-center">
              <div className="text-sm font-medium">HIVE Surface</div>
              <div className="text-xs text-hive-text-secondary">bg-hive-surface</div>
            </div>
            <div className="p-4 bg-hive-gold text-hive-canvas rounded-lg text-center">
              <div className="text-sm font-medium">HIVE Gold</div>
              <div className="text-xs opacity-70">bg-hive-gold</div>
            </div>
            <div className="p-4 bg-hive-success text-hive-canvas rounded-lg text-center">
              <div className="text-sm font-medium">HIVE Success</div>
              <div className="text-xs opacity-70">bg-hive-success</div>
            </div>
            <div className="p-4 bg-hive-error text-hive-text-primary rounded-lg text-center">
              <div className="text-sm font-medium">HIVE Error</div>
              <div className="text-xs opacity-70">bg-hive-error</div>
            </div>
          </div>
        </section>

        {/* Button Test */}
        <section className="space-y-4">
          <h2 className="text-2xl font-semibold text-primary">
            Button Test
          </h2>
          <div className="flex gap-4 flex-wrap">
            <button 
              className="hive-button-primary"
              style={{ 
                background: 'var(--hive-gold)',
                color: 'var(--hive-canvas)',
                padding: '12px 16px',
                borderRadius: '4px',
                border: 'none',
                fontWeight: '600'
              }}
            >
              Direct CSS Button
            </button>
            <button className="bg-primary text-primary-foreground px-4 py-3 rounded font-semibold">
              Tailwind Button
            </button>
            <button className="bg-hive-gold text-hive-canvas px-4 py-3 rounded font-semibold">
              HIVE Class Button
            </button>
          </div>
        </section>

        {/* Debug Info */}
        <section className="space-y-4">
          <h2 className="text-2xl font-semibold text-primary">
            Debug Information
          </h2>
          <div className="bg-card p-4 rounded-lg">
            <div className="text-sm space-y-2">
              <div>Canvas Color: <span className="font-mono">{getComputedStyle(document.documentElement).getPropertyValue('--hive-canvas')}</span></div>
              <div>Gold Color: <span className="font-mono">{getComputedStyle(document.documentElement).getPropertyValue('--hive-gold')}</span></div>
              <div>Surface Color: <span className="font-mono">{getComputedStyle(document.documentElement).getPropertyValue('--hive-surface')}</span></div>
            </div>
          </div>
        </section>

      </div>
    </div>
  )
} 