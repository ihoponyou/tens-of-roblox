local NumberLerp = {}

function NumberLerp.Lerp(a: number, b: number, alpha: number)
    print(type(a))
    return a + (b - a) * alpha
end

return NumberLerp