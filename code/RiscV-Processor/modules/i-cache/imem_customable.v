module imemory #(parameter  c_block_size = 2, c_line_size = 32, address_size = 32, mem_line_size = 32) (
    m_busywait_o, 
    m_read_data_o, 
    m_read_done, 
    m_clk_i, 
    m_reset_i, 
    m_read_i, 
    m_addr_i
);

    

    input m_clk_i, m_read_i, m_reset_i;
    input [address_size - c_block_size - 3:0] m_addr_i;
    // input [2**c_block_size*c_line_size - 1 : 0] m_wr_data_i;

    output reg [2**c_block_size*c_line_size - 1 : 0] m_read_data_o;
    output reg m_busywait_o;
    output reg m_read_done;

    reg [c_block_size - 1:0] byte_read_count;

    reg [mem_line_size - 1:0] memory [0:2047];

    // reg [2**c_block_size*c_line_size - 1 : 0] data_to_be_write;

    // assign data_to_be_write = m_wr_data_i[mem_line_size * byte_read_count - 1 : mem_line_size * (byte_read_count - 1)];


    // wire mem_access;

    // assign mem_access <= (m_read_i || m_wr_data_i);

    initial begin
        $readmemh("./i.mem", memory);
    end

    // assign m_read_data_o = {memory[0], memory[1], memory[2], memory[3]};
    // assign m_busywait_o = 1'b0;

    // always @(*posedge m_clk_i) begin
    //     m_busywait_o <= mem_access ? 1'b1 : 1'b0;

    // end


    //
    // always @(posedge m_clk_i, m_busywait_o) begin
    //     if(m_busywait_o) byte_read_count = byte_read_count + 1;
    // end

    parameter IDLE = 2'b00, MEM_READ = 2'b01, MEM_READ_DONE = 2'b10;

    reg [1:0] m_state, m_n_state;
    //control signals based on state
    always @(*) begin
        case (m_state)
            IDLE: begin
                m_busywait_o = 1'b0;
                // m_write_done = 1'b0;
                m_read_done = 1'b0;
            end
            MEM_READ: begin
                m_busywait_o = 1'b1;
                // m_write_done = 1'b0;
                m_read_done = 1'b0;
                // m_read_data_o[mem_line_size * byte_read_count - 1 : mem_line_size * (byte_read_count - 1)] = memory[{m_addr_i, byte_read_count}];
                // m_read_data_o = {memory[{m_addr_i, byte_read_count}], };

            end
            MEM_READ_DONE: begin
                m_busywait_o = 1'b0;
                // m_write_done = 1'b0;
                m_read_done = 1'b1;
            end
        endcase
    end
    reg [mem_line_size - 1:0] tmp_read_data;
    // always @(*)begin
    //     tmp = {m_addr_i, byte_read_count};
    // end

    always @(posedge m_clk_i, posedge m_reset_i) begin
        if (m_reset_i) begin
            m_state = IDLE;
            // m_n_state = IDLE;
            // tmp_read_data = 0;
        end
        else begin
            m_state <= m_n_state;
            m_read_data_o = m_read_data_o >> mem_line_size;
            m_read_data_o[2**c_block_size*c_line_size - 1 : 2**c_block_size*c_line_size - mem_line_size] = tmp_read_data;
        end
    end
    
    always @(posedge m_clk_i, posedge m_reset_i) begin
        if (m_reset_i) begin
            tmp_read_data = 0;
        end
        #1
        case (m_state)
            IDLE: begin
                // data_to_be_write = m_wr_data_i;
                tmp_read_data = 0;
            end
            MEM_READ: begin
                // m_read_data_o = m_read_data_o >> mem_line_size;
                tmp_read_data = memory[{m_addr_i, byte_read_count}];
                // m_read_data_o[2**c_block_size*c_line_size - 1 : 2**c_block_size*c_line_size - mem_line_size] = memory[{m_addr_i, byte_read_count}];
            end
        endcase
    end

    //state transission
    always @(*) begin
        case (m_state)
            IDLE: begin
                if(m_read_i) m_n_state = MEM_READ;
                else m_n_state = IDLE;
            end
            MEM_READ: begin
                if(&byte_read_count) m_n_state = MEM_READ_DONE;
            end
            MEM_READ_DONE: begin
                m_n_state = IDLE;
            end
        endcase
    end


    //counter
    always @(posedge m_clk_i) begin
        // #1
        case (m_state)
            IDLE: byte_read_count = 0;
            MEM_READ: byte_read_count = byte_read_count + 1;
            MEM_READ_DONE: byte_read_count = 0;
        endcase
    end
    
endmodule