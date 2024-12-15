return function(fixedLen: number)
	return { 'str', tostring(fixedLen + 4) } -- 4 extra for the length (u32)
end