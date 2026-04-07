import os

logo_large = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <!-- Transparent Background -->
  <defs>
    <linearGradient id="moonGrad" x1="0.2" y1="0.2" x2="0.8" y2="0.8">
      <stop offset="0%" stop-color="#bce3fc"/>
      <stop offset="100%" stop-color="#69aee6"/>
    </linearGradient>
    <linearGradient id="gearGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#6bafe8"/>
      <stop offset="100%" stop-color="#3c7caf"/>
    </linearGradient>
  </defs>

  <g stroke="#0c2c4d" stroke-width="16" stroke-linejoin="round" stroke-linecap="round">
    <!-- Gear Background (left half) -->
    <path d="M 256 64
             C 150 64 64 150 64 256
             C 64 362 150 448 256 448
             C 300 448 340 432 370 405
             L 256 256
             L 370 107
             C 340 80 300 64 256 64 Z" fill="url(#gearGrad)" />

    <!-- Gear Teeth -->
    <g fill="url(#gearGrad)">
      <path d="M 176 64 L 160 20 L 110 40 L 136 80 Z" />
      <path d="M 104 116 L 60 84 L 26 122 L 76 156 Z" />
      <path d="M 64 196 L 16 186 L 8 238 L 56 244 Z" />
      <path d="M 60 286 L 12 290 L 22 344 L 72 328 Z" />
      <path d="M 96 364 L 60 406 L 102 444 L 138 396 Z" />
      <path d="M 160 422 L 140 468 L 194 484 L 208 438 Z" />
    </g>

    <!-- Main Moon Face -->
    <path d="M 425 140 A 192 192 0 1 0 425 372 L 210 256 Z" fill="url(#moonGrad)" />

    <!-- Craters -->
    <g fill="#90c2e6" stroke="#5ca2db" stroke-width="6">
      <circle cx="150" cy="180" r="24" />
      <circle cx="120" cy="260" r="16" />
      <circle cx="180" cy="350" r="32" />
      <circle cx="280" cy="400" r="18" />
    </g>

    <!-- Eye -->
    <path d="M 250 140 Q 280 120 320 150 Q 300 200 250 180 Z" fill="#0c2c4d" />
    <circle cx="280" cy="155" r="12" fill="#31abf5" stroke="#c9fbff" stroke-width="4"/>
    <circle cx="283" cy="152" r="4" fill="#ffffff" stroke="none"/>
    <path d="M 220 120 Q 270 100 330 110" fill="none" stroke="#0c2c4d" stroke-width="12" stroke-linecap="round"/>

    <!-- Cube (Isometric) -->
    <g transform="translate(320, 200)">
      <polygon points="40,0 80,20 40,40 0,20" fill="#dbe6f0"/>
      <polygon points="0,20 40,40 40,80 0,60" fill="#9db1c4"/>
      <polygon points="40,40 80,20 80,60 40,80" fill="#7a92a8"/>
    </g>
  </g>
</svg>
"""

logo_mono = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <g stroke="#ffffff" stroke-width="20" stroke-linejoin="round" stroke-linecap="round">
    <!-- Gear Background (left half) -->
    <path d="M 256 64 C 150 64 64 150 64 256 C 64 362 150 448 256 448 C 300 448 340 432 370 405 L 256 256 L 370 107 C 340 80 300 64 256 64 Z" fill="none" />

    <!-- Gear Teeth -->
    <g fill="none">
      <path d="M 176 64 L 160 20 L 110 40 L 136 80 Z" />
      <path d="M 104 116 L 60 84 L 26 122 L 76 156 Z" />
      <path d="M 64 196 L 16 186 L 8 238 L 56 244 Z" />
      <path d="M 60 286 L 12 290 L 22 344 L 72 328 Z" />
      <path d="M 96 364 L 60 406 L 102 444 L 138 396 Z" />
      <path d="M 160 422 L 140 468 L 194 484 L 208 438 Z" />
    </g>

    <!-- Main Moon Face -->
    <path d="M 425 140 A 192 192 0 1 0 425 372 L 210 256 Z" fill="none" />

    <!-- Eye -->
    <path d="M 250 140 Q 280 120 320 150 Q 300 200 250 180 Z" fill="#ffffff" />
    <path d="M 220 120 Q 270 100 330 110" fill="none"/>

    <!-- Cube (Isometric) -->
    <g transform="translate(320, 200)" fill="none">
      <polygon points="40,0 80,20 40,40 0,20" />
      <polygon points="0,20 40,40 40,80 0,60" />
      <polygon points="40,40 80,20 80,60 40,80" />
    </g>
  </g>
</svg>
"""

banner = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1280 640" width="1280" height="640">
  <defs>
    <linearGradient id="moonGrad" x1="0.2" y1="0.2" x2="0.8" y2="0.8">
      <stop offset="0%" stop-color="#bce3fc"/>
      <stop offset="100%" stop-color="#69aee6"/>
    </linearGradient>
    <linearGradient id="gearGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#6bafe8"/>
      <stop offset="100%" stop-color="#3c7caf"/>
    </linearGradient>
  </defs>

  <g transform="translate(100, 100) scale(0.8)">
    <g stroke="#0c2c4d" stroke-width="16" stroke-linejoin="round" stroke-linecap="round">
      <path d="M 256 64 C 150 64 64 150 64 256 C 64 362 150 448 256 448 C 300 448 340 432 370 405 L 256 256 L 370 107 C 340 80 300 64 256 64 Z" fill="url(#gearGrad)" />
      <g fill="url(#gearGrad)">
        <path d="M 176 64 L 160 20 L 110 40 L 136 80 Z" />
        <path d="M 104 116 L 60 84 L 26 122 L 76 156 Z" />
        <path d="M 64 196 L 16 186 L 8 238 L 56 244 Z" />
        <path d="M 60 286 L 12 290 L 22 344 L 72 328 Z" />
        <path d="M 96 364 L 60 406 L 102 444 L 138 396 Z" />
        <path d="M 160 422 L 140 468 L 194 484 L 208 438 Z" />
      </g>
      <path d="M 425 140 A 192 192 0 1 0 425 372 L 210 256 Z" fill="url(#moonGrad)" />
      <g fill="#90c2e6" stroke="#5ca2db" stroke-width="6">
        <circle cx="150" cy="180" r="24" />
        <circle cx="120" cy="260" r="16" />
        <circle cx="180" cy="350" r="32" />
        <circle cx="280" cy="400" r="18" />
      </g>
      <path d="M 250 140 Q 280 120 320 150 Q 300 200 250 180 Z" fill="#0c2c4d" />
      <circle cx="280" cy="155" r="12" fill="#31abf5" stroke="#c9fbff" stroke-width="4"/>
      <circle cx="283" cy="152" r="4" fill="#ffffff" stroke="none"/>
      <path d="M 220 120 Q 270 100 330 110" fill="none" stroke="#0c2c4d" stroke-width="12" stroke-linecap="round"/>
      <g transform="translate(320, 200)">
        <polygon points="40,0 80,20 40,40 0,20" fill="#dbe6f0"/>
        <polygon points="0,20 40,40 40,80 0,60" fill="#9db1c4"/>
        <polygon points="40,40 80,20 80,60 40,80" fill="#7a92a8"/>
      </g>
    </g>
  </g>

  <g transform="translate(560, 320)">
    <text x="0" y="0" font-family="'Orbitron', 'Trebuchet MS', sans-serif" font-size="160" font-weight="bold" fill="#0c2c4d" letter-spacing="4">Lunar2D</text>
    <text x="12" y="80" font-family="'Rajdhani', 'Trebuchet MS', sans-serif" font-size="64" fill="#3c7caf" letter-spacing="2">Lua Rust Game AI</text>
  </g>
</svg>
"""

with open("assets/svg/logo-large.svg", "w", encoding='utf-8') as f:
    f.write(logo_large)
with open("assets/svg/logo-simple.svg", "w", encoding='utf-8') as f:
    f.write(logo_large.replace('width="512" height="512"', 'width="256" height="256"'))
with open("assets/svg/logo-mono.svg", "w", encoding='utf-8') as f:
    f.write(logo_mono)
with open("assets/svg/banner.svg", "w", encoding='utf-8') as f:
    f.write(banner)
