
return function(a: number, b: number, alpha: number)
    if type(a) ~= "number" then error("a is not a number") end
    if type(b) ~= "number" then error("b is not a number") end
    if type(alpha) ~= "number" then error("alpha is not a number") end
    return a + (b - a) * alpha
end
