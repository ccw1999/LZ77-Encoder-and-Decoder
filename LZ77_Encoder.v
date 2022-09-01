module LZ77_Encoder(clk,reset,chardata,valid,encode,finish,offset,match_len,char_nxt);


input 				clk;
input 				reset;
input 		[7:0] 	chardata;
output  			valid;
output  			encode;
output  			finish;
output 		[3:0] 	offset;
output 		[2:0] 	match_len;
output 	 	[7:0] 	char_nxt;


reg  					valid;
reg  					encode;
reg  					finish;
reg 		[3:0] 		offset;
reg 		[2:0] 		match_len;
reg 	 	[7:0] 		char_nxt;

reg			[3:0]		Total 	[2048:0];
reg			[3:0]		B		[16:0];
reg			[11:0]		timer;
reg			[6:0]		compare;


reg         [2:0]		state;
reg         [2:0]		next_state;

parameter   memory	 	= 3'd0;
parameter   shift      	= 3'd1;
parameter   enc      	= 3'd2;
parameter   val       	= 3'd3;
parameter   fin       	= 3'd4;

reg			[2:0]		i;
reg			[2:0]		max_L;
reg			[2:0]		max_L_C;
reg			[3:0]		step_C;
reg			[3:0]		step_E;
reg			[3:0]		I_step;
reg						money;

integer 	j, m;

wire 		[2:0]		i_modified;
assign i_modified = (i>2056-timer) ? 2056-timer : i;


// Timer
always @(posedge clk or posedge reset)
begin
	if (reset)
	begin
		timer <= 12'd0;
	end

	else
	begin

		case(state)

			memory:
			begin
				if(timer == 12'd2048)
				begin
					timer <= 12'd0;						
				end

				else 
				begin
					timer <= timer + 12'd1;					
				end
		
			end

			shift:
			begin
				timer <= timer + 12'd1;			
			end

			default:
			begin
				timer <= timer;
			end
		endcase

	end
end

// Shifter
always @(posedge clk or posedge reset)
begin
	if(reset)
	begin
		step_C <= 4'd0;
		step_E <= 4'd0;
		max_L <= 3'd7;
		for(j=0; j<2048;j=j+1)
		begin
			Total[j] <= 4'd0;
		end
		for(j=0; j<17;j=j+1)
		begin
			B[j] <= 4'd3;
		end
	end

	else
	begin

		case(state)
			memory:
			begin
				Total[2048] <= chardata[3:0];
				for(j=0; j<2048;j=j+1)
				begin
					Total[j] <= Total[j+1];
				end
			end 

			shift:
			begin
				if (step_C <= max_L)
				begin
					B[16] <= Total[0];
					for(j=0; j<2048;j=j+1)
					begin
						Total[j] <= Total[j+1];
					end
					for(j=0; j<16; j=j+1)
					begin
						B[j] <= B[j+1];			
					end
					step_C <= step_C + 4'd1;
				end

				else
				begin
					step_C <= 4'd0;
					// i <= 3'd0;
				end

			end

			enc:
			begin
				if(step_E < 4'd9)
				begin
					step_E <= step_E + 4'd1;
				end

				else
				begin
					step_E <= 4'd0;
				end

			end

			val:
			begin
				step_C <= 4'd0;
				max_L <= max_L_C;
			end

		endcase

	end
end

always @(*)
begin
	case(state)

		enc:
		begin
			if(step_E < 4'd9)
			begin
				for(m=0; m<7; m=m+1)
				begin
					compare[m] = |(B[9+m] ^ B[(8-step_E)+m]);
				end

				casez(compare)
					7'b0000000: i = 3'd7;
					7'b?000000: i = 3'd6;
					7'b??00000: i = 3'd5;
					7'b???0000: i = 3'd4;
					7'b????000: i = 3'd3;
					7'b?????00: i = 3'd2;
					7'b??????0: i = 3'd1;
					default: 	i = 3'd0;
				endcase

			end

			else
			begin
				compare = 7'd0;
				i = 3'd0;
			end
		end

		default:
		begin
			compare = 7'd0;
			i = 3'd0;
		end
	endcase
end

always @(posedge clk or posedge reset)
begin
	if(reset)
	begin
		max_L_C <= 3'd0;
		I_step <= 4'd0;
	end

	else
	begin

		case(state)
			enc:
			begin
				if(i_modified>=max_L_C && i_modified!=3'b0)
				begin
					max_L_C <= i_modified;
					I_step <= step_E;
				end

				else 
				begin
					max_L_C <= max_L_C;
					I_step <= I_step;
				end
			end

			val:
			begin
				I_step <= 4'd0;
				max_L_C <= 3'd0;
			end
		endcase

	end

end

// for money
always @(posedge clk or posedge reset) 
begin
	if (reset)
	begin
		money <= 1'b0;
	end

	else if (timer+max_L_C == 12'd2056)
	begin
		money <= 1'b1;
	end
end


// valider
always @(posedge clk or posedge reset)
begin
	if (reset)
	begin
		valid <= 1'b0;
		offset <= 4'b0;
		match_len <= 3'b0;
		char_nxt <= 8'b0;
	end

	else
	begin
		case(state)

			shift:
			begin
				valid <= 1'b0;
				offset <= 4'b0;
				match_len <= 3'b0;
				char_nxt <= 8'b0;
			end

			enc:
			begin
				valid <= 1'b0;
				offset <= 4'b0;
				match_len <= 3'b0;
				char_nxt <= 8'b0;
			end

			val:
			begin
				valid <= 1'b1;
				offset <= I_step;
				match_len <= max_L_C;

				if(money)
				begin
					char_nxt <= 8'h24;					
				end

				else
				begin
					char_nxt <= B[9+max_L_C];			
				end
				
			end

			fin:
			begin
				valid <= 1'b0;
				offset <= 4'b0;
				match_len <= 3'b0;
				char_nxt <= 8'b0;
			end

		endcase
	end
end

// state register
always @(posedge clk or posedge reset)
begin
    if (reset)	state <= memory;

    else 		state <= next_state;
end

// next state logic
always @(*) 
begin
    case(state)

        memory : 
        begin
        	if (chardata ^ 8'h24) next_state = memory;
        	else 				  next_state = shift;
        end	


        shift : 
        begin
        	if (char_nxt == 8'h24)      next_state = fin;
        	else if (step_C == max_L)   next_state = enc;
        	else 				   		next_state = shift;
        end	

        enc :
        begin
        	if (step_E < 4'd9)    next_state = enc;
        	else 				  next_state = val;
        end

        val : next_state = shift;

        fin : next_state = fin;

        default : next_state = shift;

    endcase
end

// output logic
always @(*) 
begin
    case(state)

        memory :
	        begin	   
	        	encode = 1'b0;
				finish = 1'b0;
	        end

        shift :
	        begin	   
	        	encode = 1'b1;
				finish = 1'b0;
	        end

        enc :
	        begin
				encode = 1'b1;
				finish = 1'b0;
	        end

        val :
	        begin	   
	        	encode = 1'b1;
				finish = 1'b0;
	        end

        fin :
	        begin	   
	        	encode = 1'b0;
				finish = 1'b1;
	        end

        default :
            begin
				encode = 1'b1;
				finish = 1'b0;
            end

    endcase
end

endmodule