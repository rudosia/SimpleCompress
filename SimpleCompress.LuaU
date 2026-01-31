--!strict

--[[
	SimpleCompression Module
	Created by: park_112
	
	A high performance compression utility for Roblox using native Buffers and Zstd.

	Features:
	
	- Native Performance: Uses Roblox's EncodingService and Buffer objects.
	- Automatic Type Detection: No need to specify data types during decompression.
	- Universal Support: Handles strings, numbers, booleans, and nested tables.
	- Luau Strict Mode: Fully typed for high performance and error catching.

	Usage:

	Compression.Compress(args: Input, Level)
		- Serializes and compresses data into a memory-efficient buffer.
		- Args:
			* Input (string | number | boolean | table) - The data to be compressed.
			* Level (number?) - Zstd compression level (0 to 3). Defaults to 3.
		- Returns:
			* buffer - The compressed data.

	Compression.Decompress(args: CompressedBuffer)
		- Reverses the compression and restores the original data type.
		- Args:
			* CompressedBuffer (buffer) - The buffer returned by the Compress function.
		- Returns:
			* any - The original data (Table, String, Number, or Boolean).

	Types:

	Compression.Compressible
		- A union type representing all valid data types the module can process.

	Compression.CompressionLevel
		- A number range from 0 (lowest/fastest) to 3 (highest/slowest).

	Usage Example:

	local Compression = require(path.To.Compression)

	-- Compressing a complex table
	local Inventory = {
		Gold = 500,
		Items = {"Sword", "Shield", "Potion"},
		Settings = { MusicVolume = 0.5, Muted = false }
	}

	local CompressedData = Compression.Compress(Inventory)
	print("Size in bytes:", buffer.len(CompressedData))

	-- Decompressing the data
	local OriginalData = Compression.Decompress(CompressedData)
	print("Item 1:", OriginalData.Items[1]) -- Output: Sword

	-- Compressing a simple string at a lower level
	local MessageBuffer = Compression.Compress("Hello World", 1)

--]]

local HttpService = game:GetService("HttpService")
local EncodingService = game:GetService("EncodingService")

export type Compressible = string | number | boolean | { [any]: any }
export type CompressionLevel = number -- 0 to 3

local Compression = {}

function Compression.Compress(Input: Compressible, Level: CompressionLevel?): buffer

	local SelectedLevel: number = Level or 3
	local IsTable: boolean = type(Input) == "table"

	local DataString: string = IsTable and HttpService:JSONEncode(Input) or tostring(Input)
	local SourceBuffer = buffer.fromstring(DataString)
	local SourceLen = buffer.len(SourceBuffer)

	local HeaderBuffer = buffer.create(SourceLen + 1)
	buffer.writeu8(HeaderBuffer, 0, IsTable and 1 or 0)
	buffer.copy(HeaderBuffer, 1, SourceBuffer)

	local Success, Result = pcall(function()
		return EncodingService:CompressBuffer(HeaderBuffer, Enum.CompressionAlgorithm.Zstd, SelectedLevel)
	end)

	if not Success then
		error("Compression failed: " .. tostring(Result), 2)
	end

	return Result
end

function Compression.Decompress(CompressedBuffer: buffer): any
	local Success, Result = pcall(function()
		return EncodingService:DecompressBuffer(CompressedBuffer, Enum.CompressionAlgorithm.Zstd)
	end)

	if not Success then
		error("Decompression failed (Buffer might be corrupted or invalid).", 2)
	end

	local IsTable = buffer.readu8(Result, 0) == 1

	local DataLen = buffer.len(Result) - 1
	local DataBuffer = buffer.create(DataLen)
	buffer.copy(DataBuffer, 0, Result, 1, DataLen)

	local DataString = buffer.tostring(DataBuffer)

	if IsTable then
		return HttpService:JSONDecode(DataString)
	end

	return DataString
end

return Compression
