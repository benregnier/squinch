-- squinch
-- MIDI-->CV looper
-- enc 1: select active loop
-- enc 2: decay / loop start
-- enc 2: quantization / loop end
-- key 1: alt
-- key 2: sync active loop
-- key 3: reverse active loop

engine.name = 'PolyPerc'

cf = 64
decay = 16 -- velocity decay
m = midi.connect()
alt = false

ppqn = 32
beats = 8 -- quarter notes
ldir = 1 -- direction

loopmax = beats*ppqn --  /12 for 32nd notes, /24 for 16th, so on
loopq = 1 ---quantization
active = 1
loop = {}
lastcc = {}

crowins = {0,0}
crowmode = {"v/oct", "velocity","trigger", "gate", "envelope"}
crowouts = {1,5,1,5}
crowloop = {1,1,2,2}

local midi_devices
local midi_device
local midi_channel

engineout = true
crowout = true
midiout = true

function init()
  active = 1
  for l = 1, 16 do
    loop[l] = {
      pos = 1,
      length = loopmax,
      midi = {},
      note = {},
      vel = {},
      cc = {},
      first = 1,
      last = loopmax,
      s = 1,  --step
      d = 16, --decay
      q = 1   --quantization
    }
    for i = 1, loop[l].length do
      loop[l].cc[i] = 63
    end
  end
  lastcc[1] = 63
  lastcc[2] = 63
  clock.run(step)

end

function step()
  while true do
    clock.sync(1/ppqn)
    for l = 1, 2 do
      if loop[l].pos > loop[l].last then loop[l].pos = loop[l].first end
      if loop[l].pos < loop[l].first then loop[l].pos = loop[l].last end
      if loop[l].cc[loop[l].pos] == nil then loop[l].cc[loop[l].pos] = 0 end
      loop[l].cc[loop[l].pos] = math.floor(lastcc[l] + loop[l].cc[loop[l].pos] / 2)
      if loop[l].note[loop[l].pos] ~= nil then 
        d2cv(loop[l].pos, l, 1) 
      end
      loop[l].pos = loop[l].pos + loop[l].s
    end
    redraw()
  end
    
end

function redraw()
  screen.clear()
  for l = 1, 2 do
    for i=1,loopmax do
      if i == loop[l].pos then 
        screen.level(15)
      elseif i >= loop[l].first and i <= loop[l].last then
        if active == l then
          if alt then screen.level(12) else screen.level(8) end
        else
          screen.level(2)
        end
      else 
        screen.level(1)
      end
      screen.move((i)%128, (math.floor((i-1)/128) + (l*3) - 2)*10)
      if loop[l].note[i] == nil then
        screen.line_rel(0,-1)
        screen.stroke()
      else
        screen.line_rel(0,loop[l].vel[i]/-16 - 1)
        screen.stroke()
      end
      --if loop[l].cc[i] == nil then
      --else
        --screen.line_rel(0,loop[l].cc[i]/16)
        --screen.stroke()
      --end
      --if loop[l].first == i or loop[l].last == i then
      --  if alt then screen.level(15) else screen.level(8) end
      --  screen.line_rel(0,2)
      --  screen.stroke()
      --end
    end
  end
  if alt then screen.level(5) else screen.level(15) end
  screen.move(10, 60)
  screen.text("Decay: " .. loop[active].d .. "   Quant: 1/" .. 128/loop[active].q)
  screen.update()
end

function enc(en,ed)
  if en==1 then
    active = util.clamp(active + ed, 1, 2)
  end
  if en==3 then
    if alt then
      loop[active].last = util.clamp(loop[active].last + ed*loop[active].q, loop[active].first, loop[active].length)
    else
      if ed == 1 and loop[active].q < 128 then
        loop[active].q = loop[active].q*2
      elseif ed == -1 and loop[active].q > 1 then
        loop[active].q = loop[active].q/2 
      end
    end
  end
  if en==2 then
    if alt then
      loop[active].first = util.clamp(loop[active].first + ed*loop[active].q, 1, loop[active].last)
    else
      loop[active].d = util.clamp(loop[active].d + ed,0, 32)
    end
  end
end

function key(kn,kz)
  print("Key ".. kn .. " Dir ".. kz)
  if kn==1 then
    alt = kz==1

  elseif kn==3 and kz==1 then
    loop[active].s = loop[active].s * -1  --reverse
  
  elseif kn==2 and kz==1 then
    if active == 1 then loop[1].pos = loop[2].pos end
    if active == 2 then loop[2].pos = loop[1].pos end
  end
end


function midi_to_hz(note)
  local hz = (440 / 32) * (2 ^ ((note - 9) / 12))
  return hz
end

function midi_to_voct(note)
  local v = util.clamp((note - 24) / 12, 0, 12) --0v = C1
  return v
end

function midi_to_cv(cc)
  local v = util.clamp(12* cc/127)
  return v
end

m.event = function(data)
  local d = midi.to_msg(data)
  local l = active
  local pos = loop[l].pos-loop[l].pos%loop[l].q+ 1
  if d.type == "note_on" then   --- to implement: note off
    loop[l].note[pos] = d.note
    loop[l].vel[pos] = d.vel
    if loop[l].pos - pos > 0 then d2cv(pos,l,1) end
    --tab.print(d)
  end
  if d.type == "cc" then
    --tab.print(d)
    lastcc[l] = d.val
  end
end  
  
function d2cv(lpos, lnum, dtype)  
  if loop[lnum].note[lpos] ~= nil then
    if dtype == 1 then
      if engineout then
        engine.amp(loop[lnum].vel[lpos] / 127)
        engine.hz(midi_to_hz(loop[lnum].note[lpos]))
        engine.cutoff(util.linexp(0,127,300,12000,loop[lnum].cc[lpos]))
      end
      if midiout then  --midi out to be implemented, based on awake (note off behavior)
      end
      if crowout then  --crowmode = {"v/oct", "velocity","trigger", "gate", "envelope"}
        for i = 1, 4 do
          if crowloop[i] == lnum then
            if crowouts[i] == 1 then --v/oct
              crow.output[i].volts = midi_to_voct(loop[lnum].note[lpos])
            elseif crowouts[i] == 2 then
              crow.output[i].volts = midi_to_cv(loop[lnum].vel[lpos])
            elseif crowouts[i] == 3 then
              crow.output[i].action = "pulse(0.1,".. (loop[lnum].vel[lpos]/127 * 7 + 1) .. ",1)"  --variable strength pulse, 1v to 8v
              crow.output[i]()
            elseif crowouts[i] == 4 then
              crow.output[i].action = "pulse(" .. (loop[lnum].vel[lpos]/127 * 0.4 + 0.1) .. ",5,1)"  --variable length 5v pulse, .1 to .5 sec
              crow.output[i]()
            elseif crowouts[i] == 5 then
              --crow.output[i].action = "{ to(8, 0, 'linear'), to(0," .. (loop[lnum].vel[lpos]/127 * 0.4 + 0.1) .. ", 'logarithmic') }" --variable time envelope (deprecated)
              crow.output[i].action = "{ to(".. (loop[lnum].vel[lpos]/127 * 7) .. ", 0, 'linear'), to(0, 'logarithmic') }"  --variable release envelope, 0v to 8v
              crow.output[i]()
            end
          end
        end
      end
      loop[lnum].vel[lpos] = loop[lnum].vel[lpos] - loop[lnum].d
      if loop[lnum].vel[lpos] <= 0 then
        loop[lnum].note[lpos] = nil
        loop[lnum].vel[lpos] = nil
      end
    end
    
    
  elseif dtype == 2 then  -- future implementation of cc output if desired
    if d.cc == 1 then
      if d.val == 1 then
        ---do something here
      elseif d.val == 127 then
        ---do something here
      end
    end
  end
  
end
