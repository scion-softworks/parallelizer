return function(fixedLen: number)
	return { 'str', tostring(fixedLen + 1) } -- 1 extra for the length
end