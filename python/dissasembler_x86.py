code = "55 31 D2 89 E5 8B 45 08 56 8B 75 0C 53 8D 58 FF 0F B6 0C 16 88 4C 13 01 83 C2 01 84 C9 75 F1 5B 5E 5D C3"


MASK_INST = 0b11111000
#ModR/M
MASK_MOD = 0b11000000
MASK_REG_OP = 0b00111000
MASK_R_M = 0b00000111
#Extra 3 bits for aux opcode
MASK_3BIT = 0b00000111
#SIB
MASK_SS = 0b11000000
MASK_IDX = 0b00111000
MASK_BASE = 0b00000111

OPCODE_TYPE = {0:"PREFIX", 1:"OPCODE", 2:"JUMP"}

#OPCODES
opcode = dict()
opcode[0x50] = {"op_size":1, "mnemonic":"push", "len":1, "type":1, "bits":32, "params":True}
opcode[0x58] = {"op_size":1, "mnemonic":"pop", "len":1, "type":1, "bits":32, "params":True}
opcode[0x31] = {"op_size":1, "mnemonic":"xor", "len":2, "type":1, "bits":32, "params":True}
opcode[0x89] = {"op_size":1, "mnemonic":"mov", "len":2, "type":1, "bits":32, "params":True}
opcode[0x0f] = {"op_size":2, "opcode":0x0fb6, "mnemonic":"movzx", "len":4, "type":1, "bits":32, "params":True}
opcode[0x8b] = {"op_size":1, "mnemonic":"mov", "len":3, "type":1, "bits":32, "params":True}
opcode[0x8d] = {"op_size":1, "mnemonic":"lea", "len":3, "type":1, "bits":32, "params":True}
opcode[0x88] = {"op_size":1, "mnemonic":"mov", "len":4, "type":1, "bits":32, "params":True}
opcode[0x83] = {"op_size":1, "mnemonic":"add", "len":3, "type":1, "bits":32, "params":True}
opcode[0x84] = {"op_size":1, "mnemonic":"test", "len":2, "type":1, "bits":8, "params":True}
opcode[0xc3] = {"op_size":1, "mnemonic":"ret", "len":1, "type":1, "bits":32, "params":None}
opcode[0x75] = {"op_size":1, "mnemonic":"jne", "len":2, "type":2, "bits":8, "params":True}
#Registros
registers = {0:{8:"al", 16:"ax", 32:"eax"},
             1:{8:"cl", 16:"cx", 32:"ecx"},
             2:{8:"dl", 16:"dx", 32:"edx"},
             3:{8:"bl", 16:"bx", 32:"ebx"},
             4:{8:"ah", 16:"sp", 32:"esp"},
             5:{8:"ch", 16:"bp", 32:"ebp"},
             6:{8:"dh", 16:"si", 32:"esi"},
             7:{8:"bh", 16:"di", 32:"edi"}}

def signed8bits(value):
    return -(value & 0x80) | (value & 0x7f)

def signed16bits(value):
    return -(value & 0x8000) | (value & 0x7fff)

def modrm_byte(value):
    return (value & MASK_MOD),(value & MASK_REG_OP)>>3,(value & MASK_R_M)

def sib_byte(value):
    return (value & MASK_SS),(value & MASK_IDX)>>3,(value & MASK_BASE)

def get_op_obj(value):
    op_byte = int(value, base=16)
    op = int(value, base=16) & MASK_INST

    if not opcode.has_key(op_byte):
        if not opcode.has_key(op):
            op = None
        else:
            op = opcode[op]
    else:
        op = opcode[op_byte]

    return op


print("Dissasembling: " + code)
code_list = code.split()
code_size = len(code.split())
offset = 0

for idx in range(code_size):
    if (idx + offset) >= code_size:
        break

    op_byte = code_list[idx+offset]
    op_obj = get_op_obj(op_byte)
    
    if not op_obj:
        print("Unknown instruction code: " + op_byte)
        continue

    instruction = op_obj["mnemonic"]

    
    if OPCODE_TYPE[op_obj["type"]] == "JUMP":
        parameters = code_list[idx+offset+1:idx+offset+op_obj["len"]]
        jump = signed8bits(int(parameters[0], base=16))
        parameters = hex((idx + offset + op_obj["len"]) + jump)
    elif OPCODE_TYPE[op_obj["type"]] == "PREFIX":
        pass
    else:
        if not op_obj["params"]:
            print '0x{:0>8x}\t{}'.format(idx+offset, instruction)
            continue

        param_list = code_list[idx+offset+op_obj["op_size"]:idx+offset+op_obj["len"]]
        
        if op_obj["len"] > 1:
            mode, modr_m, r_m = modrm_byte(int(param_list[0], base=16))
            if op_obj["len"] == 2:
                parameters = registers[r_m][op_obj["bits"]]+", "+registers[modr_m][op_obj["bits"]]
            elif op_obj["len"] == 3:
                if mode == 0x40:
                    displacement = signed8bits(int(param_list[1], base=16))
                    if displacement < 0:
                        displacement = hex(displacement)
                    else:
                        displacement = "+" + hex(displacement)
                    parameters = registers[modr_m][op_obj["bits"]] + ", [" + registers[r_m][op_obj["bits"]] + displacement + "]"
                elif mode == 0xc0:
                    parameters = registers[modr_m][op_obj["bits"]] + ", " + str(signed8bits(int(param_list[1], base=16)))
                else:
                    parameters = param_list
            elif op_obj["len"] == 4:
                if mode == 0x40:
                    if r_m == 0x4:
                        reg_orig = registers[modr_m][8]
                        ss, index, base = sib_byte(int(param_list[1], base=16))
                        if ss == 0:
                            scale_idx = registers[index][op_obj["bits"]]
                            base_reg = registers[base][op_obj["bits"]]
                    parameters = "[" + scale_idx + "+" + base_reg + "+" + param_list[2] + "]" + ", " + reg_orig
                elif mode == 0x0:
                    if r_m == 0x4:
                        reg_dest = registers[modr_m][op_obj["bits"]]
                        ss, index, base = sib_byte(int(param_list[1], base=16))
                        if ss == 0:
                            scale_idx = registers[index][op_obj["bits"]]
                            base_reg = registers[base][op_obj["bits"]]
                    parameters = reg_dest + ", " + " [" + scale_idx + "+" + base_reg + "]"
                else:
                    parameters = param_list
        else:
            parameters = registers[int(op_byte, base=16) & MASK_3BIT][op_obj["bits"]]

    print '0x{:0>8x}\t{} {}'.format(idx+offset, instruction, parameters)
    offset += op_obj["len"]-1
