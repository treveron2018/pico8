-- demo code
left=0 right=1 up=2 down=3 fire1=4 fire2=5

function _init()
    -- must initialise the cart data with a "key" before we can use it
    cartdata("scoreboard_test")

    high_score_table.load_scores()
end

function _update60()
    if (not score_entry.entering) then
        if (btnp(left)) high_score_table.add_current_score(-100)
        if (btn(right)) high_score_table.add_current_score(100)
        if (btnp(up)) high_score_table.check_current_score(high_score_table.current_score)
    end

    high_score_table.update()
end

function _draw()
    cls()

    high_score_table.draw()

    local debug_string = "score: "..high_score_table.get_score_text(high_score_table.current_score)
    ? debug_string, 64-#debug_string*2, 114, 8
end

-->8
-- high score code
high_score_table = { magic_number = 42, pad_digits = 8, base_address=0, a=0, current_score = 0 }
high_score_table.characters = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", " " }
score_entry = { entering = false, entry_number=1, entry_character=1, cycle_colours={10,9,8,14}, current_colour=1, cycle_count=0 }

high_score_table.scores = {}

function high_score_table.update()
    if (score_entry.entering) then
        score_entry.cycle_count += 1

        if (score_entry.cycle_count > 5) then
            score_entry.cycle_count = 0
            score_entry.current_colour += 1
            if (score_entry.current_colour > #score_entry.cycle_colours) score_entry.current_colour=1
        end

        if (btnp(up)) then
            score_entry.characters[score_entry.entry_character] += 1
            if (score_entry.characters[score_entry.entry_character] > #high_score_table.characters) score_entry.characters[score_entry.entry_character] = 1
        end

        if (btnp(down)) then
            score_entry.characters[score_entry.entry_character] -= 1
            if (score_entry.characters[score_entry.entry_character] < 1) score_entry.characters[score_entry.entry_character] = #high_score_table.characters
        end

        if (btnp(right)) score_entry.entry_character = min(3, score_entry.entry_character+1)
        if (btnp(left)) score_entry.entry_character = max(1, score_entry.entry_character-1)

        if (btnp(fire2)) then
            high_score_table.scores[score_entry.entry_number].name = high_score_table.array_to_string(score_entry.characters)
            score_entry.entering = false
            high_score_table.save_scores()
        end
    end
    high_score_table.a += 0.0157
end

function high_score_table.draw()
    local title_text = "high scores"
    ? title_text, 64-#title_text*2, 10, 8

    for i=0, #high_score_table.scores-1 do
        local score = high_score_table.scores[i+1]
        local score_name = score.name
        local score_c = 8

        if (score_entry.entering and score_entry.entry_number == i+1) then
            score_name = high_score_table.array_to_string(score_entry.characters)
            score_c = score_entry.cycle_colours[score_entry.current_colour]
        end

        local score_text = score_name.."...."..high_score_table.get_score_text(score.score)
        local score_x = 64-#score_text*2
        if (not score_entry.entering) score_x += sin(high_score_table.a+i/10)*5

        ? score_text, score_x, 8*i+20, score_c

        if (score_entry.entering and score_entry.entry_number == i+1) then
            local start_x = score_x+(score_entry.entry_character-1)*4
            line (start_x, 8*i+26, start_x+2, 8*i+26,score_c)
        end
    end
end

-- adding scores using bit shifting to allow for higher values
-- taken from this thread https://www.lexaloffle.com/bbs/?tid=3577
function high_score_table.add_current_score(addition)
    high_score_table.current_score += shr(addition, 16)
end

function high_score_table.check_current_score()
    for i=1,10 do
        if (high_score_table.current_score > high_score_table.scores[i].score) then
            for j=10,i+1,-1 do
                high_score_table.scores[j] = high_score_table.scores[j-1]
            end
            score_entry.entering = true
            score_entry.entry_number = i
            score_entry.entry_character = 1
            score_entry.characters = {1,1,1}
            high_score_table.scores[i] = {name="aaa", score=high_score_table.current_score}
            return true
        end
    end
    return false
end

function high_score_table.load_scores()
    local value = dget(high_score_table.base_address)

    if (value != high_score_table.magic_number) then
        for i=1,10 do
            high_score_table.scores[i] = { name = "aaa", score = shr((11000-i*1000),16)}
        end
        return false
    end

    local current_address = high_score_table.base_address + 1
    high_score_table.scores = { }
    for i=1,10 do
        local digits = ""
        score = dget(current_address)
        digits = digits..high_score_table.int_to_char(dget(current_address+1))
        digits = digits..high_score_table.int_to_char(dget(current_address+2))
        digits = digits..high_score_table.int_to_char(dget(current_address+3))
        high_score_table.scores[i] = { name=digits, score=score }
        current_address += 4
    end

    return true
end

function high_score_table.save_scores()
    dset(high_score_table.base_address, high_score_table.magic_number)

    local current_address = high_score_table.base_address + 1
    for i=1,10 do
        dset(current_address, high_score_table.scores[i].score)

        dset(current_address+1, high_score_table.char_to_int(sub(high_score_table.scores[i].name,1,1)))
        dset(current_address+2, high_score_table.char_to_int(sub(high_score_table.scores[i].name,2,2)))
        dset(current_address+3, high_score_table.char_to_int(sub(high_score_table.scores[i].name,3,3)))

        current_address += 4
    end
end

function high_score_table.get_score_text(score_value)
    if (score_value == nil) return "0"

    local s = ""
    local v = abs(score_value)
    repeat
      s = shl(v % 0x0.000a, 16)..s
      v /= 10
    until (v==0)

    for p=1,high_score_table.pad_digits-#s do
        s = "0"..s
    end

    if (score_value<0)  s = "-"..s
    return s
end

function high_score_table.char_to_int(char)
    for k,v in pairs(high_score_table.characters) do
        if (v == char) return k
    end

    return -1
end

function high_score_table.int_to_char(int)
    for k,v in pairs(high_score_table.characters) do
        if (k == int) return v
    end

    return ""
end

function high_score_table.array_to_string(array)
    local string = ""
    for i=1,#array do
        string = string..high_score_table.int_to_char(array[i])
    end
    return string
end