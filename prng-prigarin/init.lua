--
-- Pseudo-Random Number Generator (PRNG)
-- License: MIT
-- 2022, 2023 Didier Willis
--
-- There are algorithms were a bit of randomness is expected, but
-- where one would expect a reproducible output.
-- Using math.random() there would yield always different results...
-- and using math.randomseed() is also problematic: it's global and could be
-- affected elsewhere, etc.
-- So one may need instead a "fake" PRNG, that spits out a seemingly uniform
-- distribution of "random" numbers.
--
-- The algorithm below was just found on the Internet, where it was stated to
-- be "common in Monte Carlo randomizations."
--
-- I am not so lazy not to check, and traced it back to Sergei M. Prigarin,
-- _Spectral Models of Random Fields in Monte Carlo Methods_, 2001.
-- It is a "multiplicative generator", a popular type of modelling algorithms
-- of a sequence of pseudorandom numbers uniformly distributed on the interval
-- (0,1), initially studied by P.H. Lehmer around 1951.
-- This derivation, if I read correctly, has a 2^40 module and 5^17 mutiplier
-- (cycle length 2^38).
-- For information; the seeds are (X1, X2), here set to (0, 1). The algorithm
-- can be seeded with other values.
-- I didn't check the whole book...), but it seems the constraints are
-- 0 < X1, X2 <= 2^20 and X2 being odd.

local A1, A2 = 727595, 798405  -- 5^17=D20*A1+A2
local D20, D40 = 1048576, 1099511627776  -- 2^20, 2^40

local PRNG = pl.class({
  X1 = 0,
  X2 = 1,
  _init = function (self, seed)
    if seed then -- Just seeding X1
      self.X1 = math.abs(seed) % D20
    end
  end,
  random = function (self)
    local U = self.X2 * A2
    local V = (self.X1 * A2 + self.X2 * A1) % D20
    V = (V * D20 + U) % D40
    self.X1 = math.floor(V / D20)
    self.X2 = V - self.X1 * D20
    return V / D40
  end,
})

return PRNG
