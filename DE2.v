module DE2(
	input CLOCK_50,
	output reg [6:0] HEX0,
	output reg [6:0] HEX1,
	output reg [6:0] HEX2,
	output reg [6:0] HEX3,
	output reg [6:0] HEX4,
	output reg [6:0] HEX5,
	output reg [6:0] HEX6,
	output reg [6:0] HEX7	
);

reg [6:0] digit_segment [0:9];
reg [6:0] mirror_digit_segment [0:9];
initial begin
	digit_segment[0] = 7'b1000000;
	digit_segment[1] = 7'b1111001;
	digit_segment[2] = 7'b0100100;
	digit_segment[3] = 7'b0110000;
	digit_segment[4] = 7'b0011001;
	digit_segment[5] = 7'b0010010;
	digit_segment[6] = 7'b0000010;
	digit_segment[7] = 7'b1111000;
	digit_segment[8] = 7'b0000000;
	digit_segment[9] = 7'b0010000;
	
	mirror_digit_segment[0] = 7'b1000000;
	mirror_digit_segment[1] = 7'b1111001;
	mirror_digit_segment[2] = 7'b0010010;
	mirror_digit_segment[3] = 7'b0000110;
	mirror_digit_segment[4] = 7'b0101001;
	mirror_digit_segment[5] = 7'b0100100;
	mirror_digit_segment[6] = 7'b0000100;
	mirror_digit_segment[7] = 7'b1110001;
	mirror_digit_segment[8] = 7'b0000000;
	mirror_digit_segment[9] = 7'b0100000;
end

reg [3:0] number [0:7];
initial begin
	number[7] = 4'd2;
	number[6] = 4'd2;
	number[5] = 4'd5;
	number[4] = 4'd2;
	number[3] = 4'd0;
	number[2] = 4'd4;
	number[1] = 4'd7;
	number[0] = 4'd3;
end

reg [27:0] clk_div;
always @(posedge CLOCK_50) begin
	clk_div <= clk_div + 1;
end

// T = 2^N / Clock
// 5 = 2^N / 50Mhz -> N = 27,9 -> thanh ghi 28 bit

reg [3:0] effect;
always @(posedge clk_div[27]) begin 
		effect <= effect + 1;
end

// blinking
// T = 2^24 / Clock = 0.36s blink 
reg blink;
always @(posedge clk_div[23]) begin
	blink <= ~blink;
end

reg flash;
always @(posedge clk_div[20]) begin
	flash <= ~flash;
end
// left-to-right
reg [3:0] left_right [0:7];
reg [3:0] shift_count = 0;
integer i;
always @(posedge clk_div[22]) begin 
	if(shift_count < 8) begin 
		left_right[shift_count] <= number[shift_count];
		shift_count = shift_count + 1;
	end else begin
		for(i=1; i<8; i=i+1) begin
			left_right[i-1] <= left_right[i];
		end
		left_right[7] <= number[(shift_count-1)%8];
		shift_count <= shift_count + 1;
	end
end

reg [31:0] numbers = 32'h22520473; 
// right-to-left
reg [3:0] right_left [0:7];
reg [3:0] shift_count_rl = 0;
always @(posedge clk_div[22]) begin 
    if(shift_count_rl < 8) begin 
        right_left[7-shift_count_rl] <= number[7-shift_count_rl];
        shift_count_rl = shift_count_rl + 1;
    end else begin
        right_left[7] <= right_left[6];
        right_left[6] <= right_left[5];
        right_left[5] <= right_left[4];
        right_left[4] <= right_left[3];
        right_left[3] <= right_left[2];
        right_left[2] <= right_left[1];
        right_left[1] <= right_left[0];
        right_left[0] <= numbers[(shift_count_rl - 8) * 4 +: 4]; // Correct index calculation for wrapping around
        shift_count_rl <= shift_count_rl + 1;
    end
end



// even-odd
reg toggle;
always @(posedge clk_div[24]) begin
	toggle <= ~toggle;
end

// display stack
reg [3:0] display_stack;
always @(posedge clk_div[22]) begin 
	if(display_stack >= 10)
		display_stack = 0;
	else 
		display_stack <= display_stack + 1;
	
end

// direction
reg [3:0] index;
reg direction;
always @(posedge clk_div[22]) begin 
	if (direction == 0) begin
		if (index < 8) 
			index <= index + 1;
		else 
			direction <= 1;
	end else begin
		if (index > 0)
			index <= index - 1;
		else 
			direction <= 0;
	end
end

// tetris
reg [3:0] count_tetris;
always @(posedge clk_div[22]) begin
	if(count_tetris >= 5)
		count_tetris = 0;
	else 
		count_tetris <= count_tetris + 1;
end


// countdown
reg [3:0] start_countdown [0:7];
integer j;
initial begin
    start_countdown[7] = 4'd8;
    start_countdown[6] = 4'd8;
    start_countdown[5] = 4'd8;
    start_countdown[4] = 4'd8;
    start_countdown[3] = 4'd8;
    start_countdown[2] = 4'd8;
    start_countdown[1] = 4'd8;
    start_countdown[0] = 4'd8;
end

always @(posedge clk_div[23]) begin
	integer all_zero;
    all_zero = 1;
    for (j = 0; j < 8; j = j + 1) begin
        if (start_countdown[j] > number[j]) begin
            start_countdown[j] <= start_countdown[j] - 1;
            all_zero = 0;
        end
    end
    if (all_zero) begin
        for (j = 0; j < 8; j = j + 1) begin
            start_countdown[j] <= 4'd8;
        end
    end
end


always @(*) begin
	case (effect)
		4'b0000: begin 
			HEX0 = digit_segment[start_countdown[0]];
			HEX1 = digit_segment[start_countdown[1]];
			HEX2 = digit_segment[start_countdown[2]];
			HEX3 = digit_segment[start_countdown[3]];
			HEX4 = digit_segment[start_countdown[4]];
			HEX5 = digit_segment[start_countdown[5]];
			HEX6 = digit_segment[start_countdown[6]];
			HEX7 = digit_segment[start_countdown[7]];
		end
		
		4'b0001: begin
			HEX0 = digit_segment[left_right[0]];
			HEX1 = digit_segment[left_right[1]];
			HEX2 = digit_segment[left_right[2]];
			HEX3 = digit_segment[left_right[3]];
			HEX4 = digit_segment[left_right[4]];
			HEX5 = digit_segment[left_right[5]];
			HEX6 = digit_segment[left_right[6]];
			HEX7 = digit_segment[left_right[7]];
		end
		
		4'b0010: begin 
			HEX0 = (toggle) ? digit_segment[number[0]] : 7'b1111111;
			HEX1 = (!toggle) ? digit_segment[number[1]] : 7'b1111111;
			HEX2 = (toggle) ? digit_segment[number[2]] : 7'b1111111;
			HEX3 = (!toggle) ? digit_segment[number[3]] : 7'b1111111;
			HEX4 = (toggle) ? digit_segment[number[4]] : 7'b1111111;
			HEX5 = (!toggle) ? digit_segment[number[5]] : 7'b1111111;
			HEX6 = (toggle) ? digit_segment[number[6]] : 7'b1111111;
			HEX7 = (!toggle) ? digit_segment[number[7]] : 7'b1111111;
		end
		
		4'b0011: begin 
			HEX0 = (toggle) ? digit_segment[number[0]] : 7'b1111111;
			HEX1 = (toggle) ? digit_segment[number[1]] : 7'b1111111;
			HEX2 = (!toggle) ? digit_segment[number[2]] : 7'b1111111;
			HEX3 = (!toggle) ? digit_segment[number[3]] : 7'b1111111;
			HEX4 = (toggle) ? digit_segment[number[4]] : 7'b1111111;
			HEX5 = (toggle) ? digit_segment[number[5]] : 7'b1111111;
			HEX6 = (!toggle) ? digit_segment[number[6]] : 7'b1111111;
			HEX7 = (!toggle) ? digit_segment[number[7]] : 7'b1111111;
		end
		
		4'b0100: begin 
			HEX0 = (toggle) ? digit_segment[number[0]] : 7'b1111111;
			HEX1 = (!toggle) ? digit_segment[number[1]] : 7'b1111111;
			HEX2 = (!toggle) ? digit_segment[number[2]] : 7'b1111111;
			HEX3 = (toggle) ? digit_segment[number[3]] : 7'b1111111;
			HEX4 = (toggle) ? digit_segment[number[4]] : 7'b1111111;
			HEX5 = (!toggle) ? digit_segment[number[5]] : 7'b1111111;
			HEX6 = (!toggle) ? digit_segment[number[6]] : 7'b1111111;
			HEX7 = (toggle) ? digit_segment[number[7]] : 7'b1111111;
		end
		
		4'b0101: begin 
			HEX0 = 7'b1111111;
			HEX1 = 7'b1111111;
			HEX2 = 7'b1111111;
			HEX3 = 7'b1111111;
			HEX4 = 7'b1111111;
			HEX5 = 7'b1111111;
			HEX6 = 7'b1111111;
			HEX7 = 7'b1111111; 
			
			if(display_stack >=0) HEX0 = digit_segment[number[0]];
			if(display_stack >=1) HEX1 = digit_segment[number[1]];
			if(display_stack >=2) HEX2 = digit_segment[number[2]];
			if(display_stack >=3) HEX3 = digit_segment[number[3]];
			if(display_stack >=4) HEX4 = digit_segment[number[4]];
			if(display_stack >=5) HEX5 = digit_segment[number[5]];
			if(display_stack >=6) HEX6 = digit_segment[number[6]];
			if(display_stack >=7) HEX7 = digit_segment[number[7]];
		end
		
		4'b0110: begin
			HEX0 = 7'b1111111;
			HEX1 = 7'b1111111;
			HEX2 = 7'b1111111;
			HEX3 = 7'b1111111;
			HEX4 = 7'b1111111;
			HEX5 = 7'b1111111;
			HEX6 = 7'b1111111;
			HEX7 = 7'b1111111; 
			
			if(display_stack >=3) HEX0 = digit_segment[number[0]];
			if(display_stack >=2) HEX1 = digit_segment[number[1]];
			if(display_stack >=1) HEX2 = digit_segment[number[2]];
			if(display_stack >=0) HEX3 = digit_segment[number[3]];
			if(display_stack >=4) HEX4 = digit_segment[number[4]];
			if(display_stack >=5) HEX5 = digit_segment[number[5]];
			if(display_stack >=6) HEX6 = digit_segment[number[6]];
			if(display_stack >=7) HEX7 = digit_segment[number[7]];
		end
		
		4'b0111: begin
			if(flash) begin 
				HEX0 = digit_segment[number[0]];
				HEX1 = digit_segment[number[1]];
				HEX2 = digit_segment[number[2]];
				HEX3 = digit_segment[number[3]];
				HEX4 = digit_segment[number[4]];
				HEX5 = digit_segment[number[5]];
				HEX6 = digit_segment[number[6]];
				HEX7 = digit_segment[number[7]];
			end else begin 
				HEX0 = 7'b1111111;
				HEX1 = 7'b1111111;
				HEX2 = 7'b1111111;
				HEX3 = 7'b1111111;
				HEX4 = 7'b1111111;
				HEX5 = 7'b1111111;
				HEX6 = 7'b1111111;
				HEX7 = 7'b1111111;
			end
		end
		
		4'b1000: begin
			HEX0 = 7'b1111111;
			HEX1 = 7'b1111111;
			HEX2 = 7'b1111111;
			HEX3 = 7'b1111111;
			HEX4 = 7'b1111111;
			HEX5 = 7'b1111111;
			HEX6 = 7'b1111111;
			HEX7 = 7'b1111111;
			
			if (index >= 0) HEX0 = digit_segment[number[0]];
			if (index >= 1) HEX1 = digit_segment[number[1]];
			if (index >= 2) HEX2 = digit_segment[number[2]];
			if (index >= 3) HEX3 = digit_segment[number[3]];
			if (index >= 4) HEX4 = digit_segment[number[4]];
			if (index >= 5) HEX5 = digit_segment[number[5]];
			if (index >= 6) HEX6 = digit_segment[number[6]];
			if (index >= 7) HEX7 = digit_segment[number[7]];
		end
		
		4'b1001: begin
			HEX0 = 7'b1111111;
			HEX1 = 7'b1111111;
			HEX2 = 7'b1111111;
			HEX3 = 7'b1111111;
			HEX4 = 7'b1111111;
			HEX5 = 7'b1111111;
			HEX6 = 7'b1111111;
			HEX7 = 7'b1111111;
		
			// left + right to center
			if (index >= 0) HEX0 = digit_segment[number[0]];
			if (index >= 1) HEX1 = digit_segment[number[1]];
			if (index >= 2) HEX2 = digit_segment[number[2]];
			if (index >= 3) HEX3 = digit_segment[number[3]];
			if (index >= 3) HEX4 = digit_segment[number[4]];
			if (index >= 2) HEX5 = digit_segment[number[5]];
			if (index >= 1) HEX6 = digit_segment[number[6]];
			if (index >= 0) HEX7 = digit_segment[number[7]];
			
			if (index >= 7) HEX0 = 7'b1111111;
			if (index >= 6) HEX1 = 7'b1111111;
			if (index >= 5) HEX2 = 7'b1111111;
			if (index >= 4) HEX3 = 7'b1111111;
			if (index >= 4) HEX4 = 7'b1111111;
			if (index >= 5) HEX5 = 7'b1111111;
			if (index >= 6) HEX6 = 7'b1111111;
			if (index >= 7) HEX7 = 7'b1111111;
		end
		
		4'b1010: begin
			HEX0 = 7'b1111111;
			HEX1 = 7'b1111111;
			HEX2 = 7'b1111111;
			HEX3 = 7'b1111111;
			HEX4 = 7'b1111111;
			HEX5 = 7'b1111111;
			HEX6 = 7'b1111111;
			HEX7 = 7'b1111111;
			
			if(count_tetris>=0) begin 
				HEX0 = 7'b1110111; HEX1 = 7'b1111111; HEX2 = 7'b1111111; HEX3 = 7'b1110111;
				HEX4 = 7'b1110111; HEX5 = 7'b1110111; HEX6 = 7'b1110111; HEX7 = 7'b1110111;
			end
			
			if(count_tetris>=1) begin
				HEX0 = 7'b1110011; HEX1 = 7'b1111011; HEX2 = 7'b1111011; HEX3 = 7'b1100011;
				HEX4 = 7'b1100111; HEX5 = 7'b1110011; HEX6 = 7'b1100111; HEX7 = 7'b1100111;
			end
			
			if(count_tetris>=2) begin 
				HEX0 = 7'b0110011; HEX1 = 7'b1111011; HEX2 = 7'b0111011; HEX3 = 7'b1100011;
				HEX4 = 7'b0100111; HEX5 = 7'b0110011; HEX6 = 7'b0100111; HEX7 = 7'b0100111;
			end
			
			if(count_tetris>=3) begin 
				HEX0 = 7'b0110001; HEX1 = 7'b1111001; HEX2 = 7'b0011001; HEX3 = 7'b1000001;
				HEX4 = 7'b0100101; HEX5 = 7'b0010011; HEX6 = 7'b0100101; HEX7 = 7'b0100101;
			end
			
			if(count_tetris>=4) begin 
				HEX0 = 7'b0110000; HEX1 = 7'b1111000; HEX2 = 7'b0011001; HEX3 = 7'b1000000;
				HEX4 = 7'b0100100; HEX5 = 7'b0010010; HEX6 = 7'b0100100; HEX7 = 7'b0100100;
			end
		end
		
		4'b1011: begin 
			HEX0 = digit_segment[right_left[0]];
			HEX1 = digit_segment[right_left[1]];
			HEX2 = digit_segment[right_left[2]];
			HEX3 = digit_segment[right_left[3]];
			HEX4 = digit_segment[right_left[4]];
			HEX5 = digit_segment[right_left[5]];
			HEX6 = digit_segment[right_left[6]];
			HEX7 = digit_segment[right_left[7]];
		end
		
		4'b1100: begin
			if(blink) begin 
				HEX0 = digit_segment[number[0]];
				HEX1 = digit_segment[number[1]];
				HEX2 = digit_segment[number[2]];
				HEX3 = digit_segment[number[3]];
				HEX4 = digit_segment[number[4]];
				HEX5 = digit_segment[number[5]];
				HEX6 = digit_segment[number[6]];
				HEX7 = digit_segment[number[7]];
			end else begin 
				HEX0 = 7'b1111111;
				HEX1 = 7'b1111111;
				HEX2 = 7'b1111111;
				HEX3 = 7'b1111111;
				HEX4 = 7'b1111111;
				HEX5 = 7'b1111111;
				HEX6 = 7'b1111111;
				HEX7 = 7'b1111111;
			end
		end
				
		4'b1101: begin
			if(blink) begin
				HEX0 = mirror_digit_segment[number[0]];
				HEX1 = mirror_digit_segment[number[1]];
				HEX2 = mirror_digit_segment[number[2]];
				HEX3 = mirror_digit_segment[number[3]];
				HEX4 = mirror_digit_segment[number[4]];
				HEX5 = mirror_digit_segment[number[5]];
				HEX6 = mirror_digit_segment[number[6]];
				HEX7 = mirror_digit_segment[number[7]];
			end else begin 
				HEX0 = digit_segment[number[0]];
				HEX1 = digit_segment[number[1]];
				HEX2 = digit_segment[number[2]];
				HEX3 = digit_segment[number[3]];
				HEX4 = digit_segment[number[4]];
				HEX5 = digit_segment[number[5]];
				HEX6 = digit_segment[number[6]];
				HEX7 = digit_segment[number[7]];
			end
		end
		
		4'b1110: begin
			HEX0 = (toggle) ? digit_segment[number[0]] : 7'b1111111;
			HEX1 = (toggle) ? digit_segment[number[1]] : 7'b1111111;
			HEX2 = (toggle) ? digit_segment[number[2]] : 7'b1111111;
			HEX3 = (toggle) ? digit_segment[number[3]] : 7'b1111111;
			HEX4 = (!toggle) ? digit_segment[number[4]] : 7'b1111111;
			HEX5 = (!toggle) ? digit_segment[number[5]] : 7'b1111111;
			HEX6 = (!toggle) ? digit_segment[number[6]] : 7'b1111111;
			HEX7 = (!toggle) ? digit_segment[number[7]] : 7'b1111111;
		end
		
		default: begin
			HEX0 = digit_segment[number[0]];
			HEX1 = digit_segment[number[1]];
			HEX2 = digit_segment[number[2]];
			HEX3 = digit_segment[number[3]];
			HEX4 = digit_segment[number[4]];
			HEX5 = digit_segment[number[5]];
			HEX6 = digit_segment[number[6]];
			HEX7 = digit_segment[number[7]];
		end
	endcase
end

endmodule