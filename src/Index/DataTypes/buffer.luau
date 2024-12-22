return function(fixedBufLen: number)
	return { 'buffer', tostring(fixedBufLen + 2) } -- 2 extra bytes for the length (u16)
end
