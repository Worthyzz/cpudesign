
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--use ieee.std_logic_arith.all;
--use IEEE.std_logic_unsigned.ALL;
--use ieee.std_logic_arith.all;

entity my_cpu is
	port(
		clk: in std_logic;
		reset: in std_logic;
		inst: in std_logic_vector(31 downto 0);	
		inst_addr: out std_logic_vector(31 downto 0);  -- 指令地址
		inst_read: out std_logic;
		data_addr: buffer std_logic_vector(31 downto 0);  -- 数据地址
		data: inout std_logic_vector(31 downto 0);
		data_read: out std_logic;
		data_write: out std_logic;
		write_avi: out std_logic;
		is_alu: out std_logic;
		reg_val: out std_logic_vector(31 downto 0);
		is_jal: out std_logic;
		opcode_val: out std_logic_vector(6 downto 0)
	    );
end entity;

architecture cpu_simple_behav of my_cpu is
	-- utype instructions, using opcode
	constant utype_lui: std_logic_vector(6 downto 0) := B"0110111";
	constant utype_auipc: std_logic_vector(6 downto 0) := B"0010111";

	-- jtype
	constant jtype_jal: std_logic_vector(6 downto 0) := B"1101111";
	
	-- itype load instructions, using opcode, funct3
	constant itype_load: std_logic_vector(6 downto 0) := B"0000011";
	constant itype_jalr: std_logic_vector(6 downto 0) := B"1100111";
	constant itype_lb: std_logic_vector(2 downto 0) := B"000";
	constant itype_lh: std_logic_vector(2 downto 0) := B"001";
	constant itype_lw: std_logic_vector(2 downto 0) := B"010";
	constant itype_lbu: std_logic_vector(2 downto 0) := B"100";
	constant itype_lhu: std_logic_vector(2 downto 0) := B"101";
	
	-- rtype alu operations, using opcode, funct3, funct7
	constant rtype_alu: std_logic_vector(6 downto 0) := B"0110011";
	constant rtype_addsub: std_logic_vector(2 downto 0) := B"000";
	constant rtype_add: std_logic_vector(6 downto 0) := B"0000000";
	constant rtype_sub: std_logic_vector(6 downto 0) := B"0100000";
	constant rtype_sll: std_logic_vector(2 downto 0) := B"001";
	constant rtype_slt: std_logic_vector(2 downto 0) := B"010";
	constant rtype_sltu: std_logic_vector(2 downto 0) := B"011";
	constant rtype_xor: std_logic_vector(2 downto 0) := B"100";
	constant rtype_srlsra: std_logic_vector(2 downto 0) := B"101";
	constant rtype_srl: std_logic_vector(6 downto 0) := B"0000000";
	constant rtype_sra: std_logic_vector(6 downto 0) := B"0100000";
	constant rtype_or: std_logic_vector(2 downto 0) := B"110";
	constant rtype_and: std_logic_vector(2 downto 0) := B"111";

	-- btype branches, using opcode, funct3
	constant btype_branch: std_logic_vector(6 downto 0) := B"1100011";
	constant btype_beq: std_logic_vector(2 downto 0) := B"000";
	constant btype_bne: std_logic_vector(2 downto 0) := B"001";
	constant btype_blt: std_logic_vector(2 downto 0) := B"100";
	constant btype_bge: std_logic_vector(2 downto 0) := B"101";
	constant btype_bltu: std_logic_vector(2 downto 0) := B"110";
	constant btype_bgeu: std_logic_vector(2 downto 0) := B"111";
	-- ltype branches, using opcode, funct3
	constant ltype_branch: std_logic_vector(6 downto 0) := B"0000011";
	constant ltype_lb: std_logic_vector(2 downto 0) := B"000";
	constant ltype_lh: std_logic_vector(2 downto 0) := B"001";
	constant ltype_lw: std_logic_vector(2 downto 0) := B"010";
	constant ltype_lbu: std_logic_vector(2 downto 0) := B"100";
	constant ltype_lhu: std_logic_vector(2 downto 0) := B"101";
	
	type regfile is array(natural range<>) of std_logic_vector(31 downto 0);
	signal regs: regfile(31 downto 0);
	
	type memoryfile is array(natural range<>) of std_logic_vector(31 downto 0);
	signal mems: memoryfile(3 downto 0);

	signal rd_write: std_logic;
	signal rd_data: std_logic_vector(31 downto 0);

	signal opcode: std_logic_vector(6 downto 0);

	signal rd: std_logic_vector(4 downto 0);
	signal rs1: std_logic_vector(4 downto 0);
	signal rs2: std_logic_vector(4 downto 0);
	signal rs1_data: std_logic_vector(31 downto 0);
	signal rs2_data: std_logic_vector(31 downto 0);

	signal funct3: std_logic_vector(2 downto 0);
	signal funct7: std_logic_vector(6 downto 0);

	signal jal_imm20_1: std_logic_vector(20 downto 1);
	signal jal_offset: std_logic_vector(31 downto 0);

	signal utype_imm31_12: std_logic_vector(31 downto 12);
	signal utype_full_imm31_0:std_logic_vector(31 downto 0);

	signal itype_imm11_0: std_logic_vector(11 downto 0);
	signal itype_all_imm: std_logic_vector(32 downto 0);

	signal btype_imm12_1: std_logic_vector(12 downto 1);
	
	signal ltype_imm11_0: std_logic_vector(11 downto 0);

	signal rtype_alu_result: std_logic_vector(31 downto 0);
	
	

	signal pc: std_logic_vector(31 downto 0);
	signal ir: std_logic_vector(31 downto 0);

	signal next_pc: std_logic_vector(31 downto 0);

	signal load_addr: std_logic_vector(31 downto 0);
	signal load_data: std_logic_vector(31 downto 0);
	signal store_addr: std_logic_vector(31 downto 0);

	signal branch_target: std_logic_vector(31 downto 0);
	signal branch_taken: std_logic;
	

	function bool2logic32(b: boolean) return std_logic_vector is
	begin
		if b then
			return X"00000001";
		else
			return X"00000000";
		end if;
	end;
	function signext8to32(b: std_logic_vector(7 downto 0)) return std_logic_vector is
		variable t: std_logic_vector(31 downto 0);
	begin
		t(7 downto 0) := b;
		t(31 downto 8) := (others=>b(7));
		return t;
	end;
	function signext16to32(h: std_logic_vector(15 downto 0)) return std_logic_vector is
		variable t: std_logic_vector(31 downto 0);
	begin
		t(15 downto 0) := h;
		t(31 downto 16) := (others=>h(15));
		return t;
	end;
begin
	-- 组合逻辑部分
	-- instruction fetch
	inst_addr <= pc;  -- 取指地址
	inst_read <= '1' when reset = '0' else '0';  -- 当reset无效时发出指令读取信号;
	ir <= inst;  -- 当前指令
	-- 数据访问
	
	
	-- store_addr <= ...
	data_addr <= load_addr when opcode=itype_load else
		     store_addr;
	data_read <= '1' when opcode=itype_load else '0';  -- 当reset无效时发出指令读取信号;
	-- data_write <= ...
	load_data <= data when funct3=itype_lw else
		     signext8to32(data(7 downto 0)) when funct3=itype_lb else
		     signext16to32(data(15 downto 0)) when funct3=itype_lh else
		     X"000000" & data(7 downto 0) when funct3=itype_lbu else
		     X"0000" & data(15 downto 0) when funct3=itype_lhu else
		     X"00000000";
	-- data <= ...
	-- ********************BY QLM decode directly from the instruction
	opcode <= ir(6 downto 0);
	rd <= ir(11 downto 7);
	rs1 <= ir(19 downto 15);
	rs2 <= ir(24 downto 20);
	funct3 <= ir(14 downto 12);
	funct7 <= ir(31 downto 25);
	-- ********************BY QLM decode directly from the instruction
	--BY QLM:the value in register 1 and 2
	rs1_data <= regs( to_integer( unsigned(rs1)) );
	rs2_data <= regs( to_integer( unsigned(rs2)) );
	
	jal_imm20_1 <= ir(31) & ir(19 downto 12) & ir(20) & ir(30 downto 21);
	jal_offset(20 downto 0) <= jal_imm20_1 & '0';
	jal_offset(31 downto 21) <= (others=>jal_imm20_1(20)); --signed extend
	
	--*****************BY QLM: the exact immediate values of specific types DIRECTLY decent from the instructions***************
	utype_imm31_12 <= ir(31 downto 12);
	
	itype_imm11_0 <= ir(31 downto 20);	
	itype_all_imm(31 downto 12) <= (others=>itype_imm11_0(11));
	load_addr <= std_logic_vector(to_signed((to_integer(signed(rs1_data)) + to_integer(signed(itype_imm11_0))),32)); --jalr
	
	btype_imm12_1 <= ir(31) & ir(7) & ir(30 downto 25) & ir(11 downto 8);
	
	ltype_imm11_0<=ir(31 downto 20);
	
	
	--*****************BY QLM: the exact immediate values of specific types DIRECTLY decent from the instructions***************
	-- ......
	-- R-type ALU operations
	--rs
	rtype_alu_result <= std_logic_vector( to_unsigned(  ( to_integer( unsigned(rs1_data)) + to_integer( unsigned(rs2_data)) ) , 32 ) )
						when funct3 = rtype_addsub and funct7 = rtype_add else
						std_logic_vector( to_unsigned(  ( to_integer( unsigned(rs1_data)) - to_integer( unsigned(rs2_data)) ) , 32 ) )
						when funct3 = rtype_addsub and funct7 = rtype_sub else
						std_logic_vector(  shift_left(unsigned(rs1_data) , to_integer(unsigned(rs2_data) ) ) ) 
						when funct3 = rtype_sll else
						X"00000001" 
						when(signed(rs1_data) < signed(rs2_data)) and funct3 = rtype_slt else
						X"00000001"
						when(unsigned(rs1_data) < unsigned(rs2_data)) and funct3 = rtype_sltu else
  						rs1_data xor rs2_data 
						when funct3 = rtype_xor else
						std_logic_vector(shift_right(unsigned(rs1_data), to_integer(unsigned(rs2_data)))) 
						when funct3 = rtype_srlsra and funct7 = rtype_srl else
						std_logic_vector(shift_right(signed(rs1_data), to_integer(signed(rs2_data)))) 
						when funct3 = rtype_srlsra and funct7 = rtype_sra else
						rs1_data or rs2_data 
						when funct3 = rtype_or else
						rs1_data and rs2_data 
						when funct3 = rtype_and else
  						X"00000000";  -- default ALU result
	--BY QLM: using opcode to decide which value shall be put into rd_data
	utype_full_imm31_0 <= utype_imm31_12 & X"000"
							when opcode = utype_lui or opcode = utype_auipc;
								
	rd_data <= 	rtype_alu_result 	
				when opcode = rtype_alu else 
				
				std_logic_vector( to_unsigned( (to_integer(unsigned(pc))+4) , 32 ) ) 	
				when opcode = jtype_jal or opcode = itype_jalr	else
				
				utype_full_imm31_0 
				when opcode = utype_lui else
				
				std_logic_vector( to_unsigned(  ( to_integer( unsigned(utype_full_imm31_0)) + to_integer( unsigned(pc)) ) , 32 ) )
				when opcode = utype_auipc else

				mems(to_integer(unsigned(data_addr))) 			
				when opcode=itype_load else
				X"00000000";  -- default rd data
				
	rd_write <= '1' when opcode = rtype_alu  --Qlm: write opration signal
						or opcode=utype_lui
						or opcode=utype_auipc
						or opcode=jtype_jal
						or opcode=itype_load;
						
	write_avi <= rd_write;	--Qlm: debug,watch if rd_write is avilable
	
	-- 分支指令
	branch_target(12 downto 0) <= btype_imm12_1 & '0' ;
	branch_target(31 downto 14) <= ( others => btype_imm12_1(12) );
	branch_taken <= '1' when 	(rs1 = rs2 and funct3 = btype_beq )
						or 		(rs1 /= rs2 and funct3 = btype_bne)
						or  	( signed(rs1) < signed(rs2) and funct3 = btype_blt)
						or		( unsigned(rs1) < unsigned(rs2) and funct3 = btype_bltu)
						or 		( signed(rs1) > signed(rs2) and funct3 = btype_bge)
						or 		( unsigned(rs1) > unsigned(rs2) and funct3 = btype_bgeu)
						else '0';
	--load
	
	-- 下一条指令地址
  	next_pc <= 
				std_logic_vector( to_unsigned( (to_integer(unsigned(pc))+to_integer(unsigned(jal_offset))) , 32 )) 
				when opcode = jtype_jal else --JAL inst add imm and pc
				
				load_addr
				when opcode = itype_jalr else --JALR inst
				
				std_logic_vector( to_unsigned( (to_integer(unsigned(pc))+to_integer(unsigned(branch_target))) , 32 ))
				when opcode = btype_branch and branch_taken ='1' else
				
				std_logic_vector(to_unsigned(to_integer(unsigned(pc)) + 4,32)); -- 需补充其它情况 
				
				
	is_jal <= '1' when opcode = jtype_jal else	--Qlm: debug watch if jal instrution avilable
				'0';
	-- ...... (其它组合逻辑)
	
	-- 时序逻辑部分
	-- pc
	pc_update: process(clk)
	begin
		if(rising_edge(clk)) then
			if(reset='1') then
				pc <= X"00000000";  -- 当reset信号有效时，pc被重置为0
			else
				pc <= next_pc;
			end if;
		end if;
	end process pc_update;

	-- regs
	reg_update: process(clk)
		variable i: integer;
		variable k: integer;
	begin
		i := to_integer(unsigned(rd));

		if(rising_edge(clk)) then
			if(reset='1') then
				-- reset all regs to 0 except reg[0]
				for k in 1 to 31 loop
					regs(k) <= X"00000000";  -- reset to 0
				end loop;	
--				regs(0) <= X"00000001";
--				regs(1) <= X"00000003";
--				regs(2) <= X"00000100";
--				mems(0) <= X"00000006";
--				mems(1) <= X"00000007";
--				mems(2) <= X"00000008";
		--BY QLM:when the write signal is available, put the result for example,the result of add inst into the register(i) 
			elsif(rd_write='1' and i /= 0) then
				regs(i) <= rd_data;
				reg_val <= regs(i);
				
				if(funct3 = rtype_addsub and funct7 = rtype_add) then
				is_alu <= '1';
				end if;
				
				opcode_val <= opcode;
				
			end if;
		
		end if;
	end process reg_update;

-- ...... (其它时序逻辑)

end;
