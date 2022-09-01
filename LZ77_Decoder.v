module LZ77_Decoder(clk,reset,code_pos,code_len,chardata,encode,finish,char_nxt);

input 				clk;
input 				reset;
input 		[3:0] 	code_pos;
input 		[2:0] 	code_len;
input 		[7:0] 	chardata;

output	 			encode;
output reg 			finish;
output reg	[7:0] 	char_nxt;

reg			[3:0]	S_B [8:0];
reg			[2:0]		timer;

assign 	encode = 1'b0;
integer j;


always @(posedge clk or posedge reset) 
begin
	if (reset) 
	begin
		timer <= 3'd0;	
	end

	else if (timer==code_len)
	begin
		timer <= 3'd0;
	end

	else
	begin
		timer <= timer + 3'd1;
	end
end

always @(posedge clk or posedge reset)
begin
	if(reset) 
	begin	
	end

	else 
	begin
		for(j=0; j<8; j=j+1)
		begin
			S_B[j+1] <= S_B[j];			
		end
		S_B[0] <= char_nxt[3:0];
	end
end

always @(posedge clk)
begin
	if ((!(|code_pos) && !(|code_len)) || timer==code_len)
	begin
		char_nxt <= chardata;
	end

	else if(!code_pos)
	begin
		char_nxt <= char_nxt;
	end

	else if(timer<=code_len)
	begin
		char_nxt <= S_B[code_pos - 1'b1];
	end

	else 
	begin
		char_nxt <= char_nxt;
	end
end

always @(posedge clk or posedge reset)
begin
	if (reset) 
	begin
		finish <= 1'b0;
	end

	else if (chardata==8'h24 && timer==code_len)
	begin
		finish <= 1'b1;
	end

	else 
	begin
		finish <= finish;
	end
end

endmodule