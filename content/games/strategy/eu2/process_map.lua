-- process_map.lua — Narzędzie do przetwarzania mapy prowincji
-- Uruchom jako main.lua w katalogu eu2/ (musi być dostęp do map.png)
--
-- Działanie:
--   1. Downscale 2x metodą głosowania 2×2 (bez nowych kolorów)
--   2. 2 przebiegi wygładzania krawędzi (głosowanie 4-sąsiadów, waga własna = 2)
--   3. Magenta (znaczniki stolic) → zastąpione kolorem prowincji
--   4. Białe piksele → 1 na prowincję, w zredukowanej pozycji,
--      z 4 sąsiadami tego samego koloru (przeszukiwanie promień 1–12)
--   5. Zapis do map2.png
--
-- Jak uruchomić:
--   1. Utwórz kopię zapasową: cp main.lua main_game.lua
--   2. Zastąp main.lua tym plikiem: cp process_map.lua main.lua
--   3. Uruchom grę eu2 ("Run: Debug — pick demo" → eu2)
--   4. Poczekaj na "Gotowe!" w konsoli i zamknij okno
--   5. Przywróć: cp main_game.lua main.lua

local MAP_IN  = "map.png"
local MAP_OUT = "map2.png"

-- Progi klasyfikacji pikseli
local WHITE_THRESH   = 240   -- r,g,b >= 240 → biały (znacznik prowincji)
local MAGENTA_R_MIN  = 180   -- r >= 180, g < 60, b >= 180 → magenta (stolica)
local MAGENTA_G_MAX  = 60
local BLACK_MAX      = 40    -- r,g,b < 40 → czarny (ocean)

-- Sąsiedzi 4-kierunkowi
local DIRS = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }

-- Pomocnicze funkcje klasyfikacji -----------------------------------------

local function is_white(r, g, b)
    return r >= WHITE_THRESH and g >= WHITE_THRESH and b >= WHITE_THRESH
end

local function is_magenta(r, g, b)
    return r >= MAGENTA_R_MIN and g < MAGENTA_G_MAX and b >= MAGENTA_R_MIN
end

local function is_black(r, g, b)
    return r < BLACK_MAX and g < BLACK_MAX and b < BLACK_MAX
end

local function is_province(r, g, b)
    return not is_white(r, g, b)
        and not is_magenta(r, g, b)
        and not is_black(r, g, b)
end

-- Kolor → klucz liczbowy i odwrotnie
local function ck(r, g, b)
    return r * 65536 + g * 256 + b
end

local function ck_rgb(k)
    local r = math.floor(k / 65536)
    local g = math.floor((k / 256) % 256)
    local b = k % 256
    return r, g, b
end

-- Czy piksel (x,y) ma 4 sąsiadów dokładnie tego samego koloru?
local function has_4_same(img, x, y, r, g, b, w, h)
    if x <= 0 or x >= w - 1 or y <= 0 or y >= h - 1 then
        return false
    end
    for _, d in ipairs(DIRS) do
        local nr, ng, nb = img:getPixel(x + d[1], y + d[2])
        if nr ~= r or ng ~= g or nb ~= b then
            return false
        end
    end
    return true
end

-- Krok 2: jeden przebieg wygładzania krawędzi -----------------------------
-- Dla każdego nieokeanicznego piksela zbieramy głosy 4 sąsiadów + własny×2.
-- Zwycięski kolor musi już istnieć na obrazie (żadnych nowych RGB).
local function smooth_once(img, w, h)
    local next = lurek.image.newImageData(w, h)
    for y = 0, h - 1 do
        for x = 0, w - 1 do
            local r, g, b, a = img:getPixel(x, y)
            if is_black(r, g, b) then
                next:setPixel(x, y, r, g, b, a)
            else
                local sk     = ck(r, g, b)
                local votes  = { [sk] = 2 }  -- waga własna = 2
                for _, d in ipairs(DIRS) do
                    local nx, ny = x + d[1], y + d[2]
                    if nx >= 0 and nx < w and ny >= 0 and ny < h then
                        local nr, ng, nb = img:getPixel(nx, ny)
                        if not is_black(nr, ng, nb) then
                            local nk = ck(nr, ng, nb)
                            votes[nk] = (votes[nk] or 0) + 1
                        end
                    end
                end
                local bk, bv = sk, 0
                for k, v in pairs(votes) do
                    if v > bv then bk = k; bv = v end
                end
                local fr, fg, fb = ck_rgb(bk)
                next:setPixel(x, y, fr, fg, fb, 255)
            end
        end
    end
    return next
end

-- =========================================================================
function lurek.init()
    print("[process_map] Wczytywanie " .. MAP_IN .. "...")
    local src = lurek.image.loadImage(MAP_IN)
    assert(src, "Błąd: nie można wczytać " .. MAP_IN)

    local W  = src:getWidth()
    local H  = src:getHeight()
    local W2 = math.floor(W / 2)
    local H2 = math.floor(H / 2)

    print(string.format(
        "[process_map] Rozmiar: %dx%d → %dx%d", W, H, W2, H2))

    -- =====================================================================
    -- Krok 1: Downscale 2x metodą głosowania w bloku 2×2
    --   – piksele białe i magenta wykluczone z głosowania
    --   – zapamiętujemy pozycję białego piksela dla każdej prowincji
    -- =====================================================================
    print("[process_map] [1/3] Downscale z głosowaniem 2×2...")

    local out = lurek.image.newImageData(W2, H2)

    -- Mapa: ck(prowincja) → {ox, oy} — pierwsza znaleziona pozycja białego piksela
    local province_white = {}

    for oy = 0, H2 - 1 do
        for ox = 0, W2 - 1 do
            local sx = ox * 2
            local sy = oy * 2

            local votes           = {}
            local found_white     = false

            for dy = 0, 1 do
                for dx = 0, 1 do
                    local px = sx + dx
                    local py = sy + dy
                    if px < W and py < H then
                        local r, g, b = src:getPixel(px, py)
                        if is_white(r, g, b) then
                            found_white = true
                        elseif is_province(r, g, b) then
                            local k = ck(r, g, b)
                            votes[k] = (votes[k] or 0) + 1
                        end
                        -- czarny i magenta → pomijane w głosowaniu
                    end
                end
            end

            local best_k, best_v = 0, 0
            for k, v in pairs(votes) do
                if v > best_v then best_k = k; best_v = v end
            end

            local r, g, b
            if best_v > 0 then
                r, g, b = ck_rgb(best_k)
                -- Zapamiętaj pierwszą pozycję białego znacznika tej prowincji
                if found_white and not province_white[best_k] then
                    province_white[best_k] = { ox, oy }
                end
            else
                -- Cały blok to ocean lub wyłącznie magenta/biały bez prowincji obok
                r, g, b = src:getPixel(sx, sy)
                if is_magenta(r, g, b) or is_white(r, g, b) then
                    r, g, b = 0, 0, 0
                end
            end

            out:setPixel(ox, oy, r, g, b, 255)
        end
    end

    -- =====================================================================
    -- Krok 2: 2× wygładzanie krawędzi (bez nowych kolorów)
    -- =====================================================================
    print("[process_map] [2/3] Wygładzanie krawędzi (2 przebiegi)...")

    out = smooth_once(out, W2, H2)
    out = smooth_once(out, W2, H2)

    -- =====================================================================
    -- Krok 3: Umieszczanie białych pikseli — 1 na prowincję
    --   Warunek: piksel musi leżeć na kolorze swojej prowincji
    --            i mieć 4 sąsiadów dokładnie tego samego koloru.
    --   Strategia:
    --     a) Sprawdź zapamiętaną pozycję po wygładzeniu
    --     b) Jeśli kolor się zmienił, znajdź najbliższy piksel prowincji (r=1..6)
    --     c) Sprawdź warunek 4-sąsiadów w promieniu r=0..12
    --     d) Awaryjnie: umieść bez sprawdzania sąsiadów
    -- =====================================================================
    print("[process_map] [3/3] Umieszczanie białych pikseli (1 na prowincję)...")

    local placed = 0
    local fallback = 0
    local skipped = 0

    for pk, pos in pairs(province_white) do
        local pr, pg, pb = ck_rgb(pk)
        local ox, oy = pos[1], pos[2]

        -- (a) Szukamy centroidu prowincji (cx,cy) — zaczynamy od zapamiętanej pozycji
        local cx, cy = ox, oy
        do
            local cur_r, cur_g, cur_b = out:getPixel(ox, oy)
            if cur_r ~= pr or cur_g ~= pg or cur_b ~= pb then
                -- Po wygładzeniu tu jest inny kolor — szukaj w pobliżu
                cx, cy = -1, -1
                for radius = 1, 6 do
                    if cx >= 0 then break end
                    for dy = -radius, radius do
                        if cx >= 0 then break end
                        for dx = -radius, radius do
                            if math.abs(dx) == radius or math.abs(dy) == radius then
                                local tx = ox + dx
                                local ty = oy + dy
                                if tx >= 0 and tx < W2 and ty >= 0 and ty < H2 then
                                    local tr, tg, tb = out:getPixel(tx, ty)
                                    if tr == pr and tg == pg and tb == pb then
                                        cx, cy = tx, ty
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        if cx < 0 then
            -- Prowincja zniknęła całkowicie po wygładzeniu (bardzo mała) → pomiń
            skipped = skipped + 1
            goto continue
        end

        -- (c) Szukaj pozycji z 4 identycznymi sąsiadami (promień 0..12)
        local placed_here = false

        if has_4_same(out, cx, cy, pr, pg, pb, W2, H2) then
            out:setPixel(cx, cy, 255, 255, 255, 255)
            placed = placed + 1
            placed_here = true
        else
            for radius = 1, 12 do
                if placed_here then break end
                for dy = -radius, radius do
                    if placed_here then break end
                    for dx = -radius, radius do
                        if math.abs(dx) == radius or math.abs(dy) == radius then
                            local tx = cx + dx
                            local ty = cy + dy
                            if tx >= 0 and tx < W2 and ty >= 0 and ty < H2 then
                                local tr, tg, tb = out:getPixel(tx, ty)
                                if tr == pr and tg == pg and tb == pb
                                    and has_4_same(out, tx, ty, pr, pg, pb, W2, H2) then
                                    out:setPixel(tx, ty, 255, 255, 255, 255)
                                    placed = placed + 1
                                    placed_here = true
                                end
                            end
                        end
                    end
                end
            end
        end

        -- (d) Awaryjnie — umieść na środku (może nie mieć 4 sąsiadów)
        if not placed_here then
            local tr, tg, tb = out:getPixel(cx, cy)
            if tr == pr and tg == pg and tb == pb then
                out:setPixel(cx, cy, 255, 255, 255, 255)
                fallback = fallback + 1
            else
                skipped = skipped + 1
            end
        end

        ::continue::
    end

    print(string.format(
        "[process_map] Białe piksele: umieszczono=%d  awaryjnie=%d  pominięto=%d",
        placed, fallback, skipped))

    -- =====================================================================
    -- Zapis
    -- =====================================================================
    print("[process_map] Zapisywanie " .. MAP_OUT .. "...")
    lurek.image.savePNG(out, MAP_OUT)
    print("[process_map] ✓ Gotowe! Zapisano: " .. MAP_OUT)

    lurek.event.quit()
end

function lurek.process(dt) end
function lurek.draw()
    lurek.render.clear(0, 0, 0, 1)
    lurek.render.print("[process_map] Przetwarzanie... sprawdź konsolę.", 10, 10)
end
