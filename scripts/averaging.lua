local Averaging = {}

function Averaging.SMA(history, window_size, item_name)
  local sum = 0
  for tick, deltas in pairs(history) do
    sum = sum + (deltas[item_name] or 0)
  end
  return sum / window_size
end

function Averaging.EMA(history, window_size, item_name, alpha)
  alpha = alpha or (2 / (window_size + 1))
  local ema = nil
  local sorted_ticks = {}
  for tick in pairs(history) do
    sorted_ticks[#sorted_ticks + 1] = tick
  end
  table.sort(sorted_ticks)
  for _, tick in ipairs(sorted_ticks) do
    local value = history[tick][item_name] or 0
    if ema == nil then
      ema = value
    else
      ema = alpha * value + (1 - alpha) * ema
    end
  end
  return ema or 0
end

return Averaging
