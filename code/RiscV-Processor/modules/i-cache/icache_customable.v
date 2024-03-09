// `include "./memory.v"

module icache #(parameter c_line_size = 32, c_assiotivity = 0, c_index = 8, c_block_size = 2, address_size = 32) (
    c_busywait_o, 
    c_data_o, 
    c_m_read_en_o, 
    c_m_address_o, 
    reset_i, 
    clk_i, 
    address_i, 
    c_read_en_i, 
    c_m_busywait_i, 
    c_m_read_data_i, 
    m_read_done_i
);

     // cache line size, assiotivity, index size, block size
    parameter c_tag_size = c_line_size - c_index - c_block_size - 2;
    // parameter c_block_size = c_line_size*(2**c_block_size);
    integer i, j;

    input reset_i, clk_i, c_read_en_i;
    input [address_size - 1:0] address_i;

    //for data memory from cache
    output reg c_m_read_en_o; 
    //c_m_wr_en_o
    
    // output  [2**c_block_size*c_line_size - 1:0] c_m_write_data_o;
    output reg [address_size - c_block_size - 3:0] c_m_address_o;
    input [2**c_block_size*c_line_size - 1:0] c_m_read_data_i;
    input c_m_busywait_i, m_read_done_i;
    // input [c_line_size - 1:0] c_write_data_i;


    output reg [c_line_size - 1:0] c_data_o;
    output reg c_busywait_o;


    reg [2**c_block_size*c_line_size - 1 : 0] c_word[0 : (2**c_index) - 1][0 : (2**c_assiotivity) - 1]; //cache word
    reg [c_tag_size - 1 : 0] c_tag[0 : (2**c_index) - 1][0 : (2**c_assiotivity) - 1];  //cache tag
    reg c_valid_bit [0 : (2**c_index) - 1][0 : (2**c_assiotivity) - 1]; //cache valid bit
    // reg c_dirty_bit [0 : (2**c_index) - 1][0 : (2**c_assiotivity) - 1]; //cache dirty bit
    reg [2:0] c_usability_bit [0 : (2**c_index) - 1][0 : (2**c_assiotivity) - 1]; //cache dirty bit

    wire [c_block_size - 1:0] offset_addr;
    wire [c_index - 1:0] index_addr;
    wire [c_tag_size - 1:0] tag_addr;


    reg valid_bit_frm_c [0 : (2**c_assiotivity) - 1];
    reg hit_frm_c [0 : (2**c_assiotivity) - 1];
    reg hit_frm_c_AND_valid_bit_frm_c [0 : (2**c_assiotivity) - 1];
    // reg dirty_bit_frm_c [0 : (2**c_assiotivity) - 1];
    reg [c_tag_size - 1 : 0] tag_frm_c [0 : (2**c_assiotivity) - 1];
    reg [2**c_block_size*c_line_size - 1:0] data_frm_c [0 : (2**c_assiotivity) - 1];
    reg [2:0] usability_bit_frm_c [0 : (2**c_assiotivity) - 1];

    // reg [c_assiotivity - 1 : 0] hit_cache_assiotivity;
    reg c_hit;

    reg [c_assiotivity - 1:0] c_hit_set_place;
    // reg [2**c_block_size*c_line_size - 1:0] c_write_data_pre;
    // reg [2**c_block_size*c_line_size - 1:0] c_write_data_pre_all_, c_block_data_with_mask, tmp;

    // always @(*) begin
    //     c_block_data_with_mask = c_word[index_addr][c_hit_set_place] & ~({c_line_size{1'b1}} << (offset_addr * c_line_size));
    //     c_write_data_pre = c_write_data_pre_all_ ^ c_write_data_i << (offset_addr * c_line_size);
    //     tmp = c_block_data_with_mask | c_write_data_pre;
        
    // end


    //{tag_addr:}{index_addr:}{offset_addr:}{2}
    assign offset_addr = address_i[c_block_size + 1:2];
    assign index_addr = address_i[c_index + c_block_size + 1:c_block_size + 2];
    assign tag_addr = address_i[c_line_size - 1:c_index + c_block_size + 2];

    // reg [c_block_size - 1:0] offset_addr_tmp;
    
    // always @(*) begin
    //     offset_addr_tmp = offset_addr;
        
    // end

    //
    wire [address_size - c_block_size - 3:0] c_m_address_read;

    //address for data memeory
    assign c_m_address_read = {address_i[address_size : c_block_size + 2]};

    // assign c_m_address_wr = {tag_frm_c[less_used_assiotivity], index_addr};

    //data for mem write
    // assign c_m_write_data_o = data_frm_c[less_used_assiotivity];


    //read data, valid bit, check tag == cache tag from cache sets
    // integer offset = offset_addr*c_line_size;
    // integer tmp;
    // always @(posedge clk) begin
    //     tmp = offset_addr*c_line_size;
    // end
    
    //cache hit checks
    always @(*) begin
        c_hit = 1'b0;
        c_hit_set_place = 0;
        for (i = 0; i < 2**c_assiotivity; i = i + 1) begin
            valid_bit_frm_c[i] = c_valid_bit[index_addr][i];
            tag_frm_c[i] = c_tag[index_addr][i];
            // dirty_bit_frm_c[i] = c_dirty_bit[index_addr][i];
            hit_frm_c[i] = (tag_addr === tag_frm_c[i]) ? 1'b1 : 1'b0;
            hit_frm_c_AND_valid_bit_frm_c[i] = valid_bit_frm_c[i] && hit_frm_c[i];
            data_frm_c[i] = c_word[index_addr][i];
            usability_bit_frm_c[i] = c_usability_bit[index_addr][i];

            if (hit_frm_c_AND_valid_bit_frm_c[i]) begin
                c_hit = 1'b1;
                c_hit_set_place = i;
                c_data_o = data_frm_c[i] >> (offset_addr * c_line_size);
            end
        end
    end

    //select less used cache assiotivity
    integer less_used_assiotivity;
    always @(*) begin
        less_used_assiotivity = 0;
        for (i = 1; i < 2**c_assiotivity; i = i + 1) begin
            if (usability_bit_frm_c[less_used_assiotivity] > usability_bit_frm_c[i]) less_used_assiotivity = i;
        end
    end

    //dirty bit wire
    // wire is_dirty;
    // assign is_dirty = dirty_bit_frm_c[less_used_assiotivity];

    reg usebility_reduce_en;

    // //busy wait
    // always @(*) begin
    //     if (!c_hit & (c_read_en_i | c_wr_en_i)) 
    //         c_busywait_o = 1'b1;
    //     else
    //         c_busywait_o = 1'b0;
    // end

    always @(*) begin
        for (i = 1; i < 2**c_assiotivity; i = i + 1) begin
            if(c_read_en_i)begin
                usebility_reduce_en = 1;
                if (c_usability_bit[index_addr][i] < 1) begin
                    usebility_reduce_en = 0;
                end
            end
        end
    end

    always @(posedge clk_i, reset_i)
    begin
        if(reset_i)
        begin
            for (i = 0; i < 2**c_index; i = i + 1) begin
                for (j = 0; j < 2**c_assiotivity; j = j + 1) begin
                    c_valid_bit[i][j] = 0;
                    c_word[i][j] = 0;
                    // c_word[i][j][1] = 0;
                    // c_word[i][j][2] = 0;
                    // c_word[i][j][3] = 0;
                    c_tag[i][j] = 0;
                    // c_dirty_bit[i][j] = 0;
                    c_usability_bit[i][j] = 0;
                end
            end
        end
        else
        begin

            if(c_allow_wr) begin
                c_valid_bit[index_addr][less_used_assiotivity] = 1'b1;
                // c_dirty_bit[index_addr][less_used_assiotivity] = 0;
                c_tag[index_addr][less_used_assiotivity] = tag_addr;
                c_word[index_addr][less_used_assiotivity] = c_m_read_data_i;
                c_usability_bit[index_addr][less_used_assiotivity] = 1'b1;

                if(usebility_reduce_en)begin
                    for (i = 0; i < 2**c_assiotivity; i = i + 1) begin
                        if(i !== less_used_assiotivity)begin
                            if (c_usability_bit[index_addr][i] > 0) begin
                                c_usability_bit[index_addr][i] = c_usability_bit[index_addr][i] - 1;
                            end
                            // else c_usability_bit[index_addr][i] = c_usability_bit[index_addr][i] - 1;
                        end
                    end
                end

                // c_usability_bit[index_addr][less_used_assiotivity] = 3'd2;
                // c_usability_bit[index_addr][less_used_assiotivity] = 3'd1;
                // c_usability_bit[index_addr][less_used_assiotivity] = 3'd4;
                // for (i = 0; i < 2**c_block_size; i = i + 1) begin
                //     c_word[index_addr][less_used_assiotivity][i] = c_m_read_data_i[(i+1)*c_line_size : i*c_line_size];
                // end

            end
        end
    end
    
    //state machine
    parameter IDLE = 2'b00, MEM_READ = 2'b01, MEM_READ_DONE = 2'b10;   //, CACHE_WRITE_BACK = 3'b011;
    reg [1:0] c_state, c_n_state;
    reg c_allow_wr; // c_update_en;
    // assign c_m_write_data_o = data_frm_c[less_used_assiotivity];

    //state transisstion
    always @(*)
    begin
        case (c_state)
            IDLE: begin
                if (!c_hit && c_read_en_i) begin
                    c_n_state <= MEM_READ;
                    // c_busywait_o <= 1'b1;
                end
                else
                    c_n_state <= IDLE;
                    // c_busywait_o <= 1'b0;
            end
            MEM_READ: begin
                if(!c_m_busywait_i && m_read_done_i) c_n_state = MEM_READ_DONE;
            end
            MEM_READ_DONE: begin
                c_n_state = IDLE;
            end
        endcase
    end

    //combination logic for cache control signals
    always @(*)
    begin
        case (c_state)
            IDLE: begin
                c_busywait_o <= (!c_hit && c_read_en_i) ? 1'b1 : 1'b0;
                c_m_read_en_o <= 1'b0;
                // c_m_wr_en_o <= 1'b0;
                c_allow_wr <= 1'b0;
                // c_update_en <= c_wr_en_i ?  1'b1 : 1'b0;
                c_m_address_o = c_m_address_read;
            end
            MEM_READ: begin
                c_busywait_o <= 1'b1;
                c_m_read_en_o <= m_read_done_i ? 1'b0 : 1'b1;
                // c_m_wr_en_o <= 1'b0;
                c_allow_wr <= m_read_done_i ? 1'b1 : 1'b0;
                // c_update_en <= 1'b0;
                c_m_address_o = c_m_address_read;
            end
            MEM_READ_DONE: begin
                c_busywait_o <= 1'b0;
                c_m_read_en_o <= 1'b0;
                // c_m_wr_en_o <= 1'b0;
                c_allow_wr <= 1'b0;
                // c_update_en <= 1'b0;
                c_m_address_o = c_m_address_read;
            end
        endcase
    end

    //cache state change
    always @(posedge clk_i, posedge reset_i) begin
        if (reset_i) begin
            c_state <= IDLE;
            // c_write_data_pre_all_ = 0;

        end
        else begin
            c_state <= c_n_state;
        end
    end

endmodule