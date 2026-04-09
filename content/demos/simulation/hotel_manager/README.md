# Hotel Manager

A skyscraper hotel management simulation where you construct floors, assign room types, and profit from guest occupancy. Each 15-second day triggers an automatic revenue cycle: guests check in and out of rooms stochastically, maintenance costs grow with building height, and a satisfaction score reflects elevator wait times and restaurant noise.

## What It Demonstrates

- `lurek.mouse.getPosition()` / `lurek.mousepressed()` — room-type assignment and floor construction clicks
- `lurek.keyboard.wasPressed()` — scroll the building view up and down, cycle selected room type
- `lurek.gfx.rectangle()` — floor grid, room panels with type-colour fill, elevator shaft
- `lurek.gfx.setColor()` — room-type palette lookup and occupancy tint overlay
- `lurek.gfx.print()` — floor labels, room icons, money HUD, and daily revenue summary
- `lurek.gfx.setBackgroundColor()` — sky gradient behind the tower
- Scrollable viewport — `scrollY` offset allows viewing a building taller than the window
- Stochastic occupancy — guest turnover is driven by daily `math.random()` rolls gated by satisfaction

## How to Run

```powershell
cargo run -- content/demos/hotel_manager
```

## Controls

| Input | Action |
|-------|--------|
| Left Click room slot | Cycle the room type for that slot |
| B | Build a new floor (costs money) |
| Up / Down Arrow | Scroll the building view |
| Tab | Cycle selected room type |
| Escape | Quit |

## Notes

- Floor cost scales as `500 + (n-1) * 300`; higher floors generate more prestige but cost more maintenance per day
- Satisfaction is calculated from elevator wait time (proportional to floor index) minus noise from neighbouring restaurants
- Room types: Empty (free), Single ($50/d), Suite ($150/d), Restaurant ($200/d), Office ($100/d)
- Occupancy toggles probabilistically each day; higher satisfaction increases the chance of rooms staying filled
