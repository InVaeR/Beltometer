local Averaging = {}

function Averaging.SMA(history, window_size, item_name)
  local n = #history
  if n < window_size then return -1 end
  local sum = 0
  for i = n - window_size + 1, n do
    sum = sum + (history[i][item_name] or 0)
  end
  return sum / window_size
end

function Averaging.EMA(history, window_size, item_name, alpha)
  local n = #history
  if n < window_size then return -1 end
  alpha = alpha or (2 / (window_size + 1))
  local ema = nil
  for i = n - window_size + 1, n do
    local value = history[i][item_name] or 0
    if ema == nil then
      ema = value
    else
      ema = alpha * value + (1 - alpha) * ema
    end
  end
  return ema
end

return Averaging
