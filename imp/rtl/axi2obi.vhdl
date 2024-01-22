
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
--                                                                              --
-- Author:         Simone Machetti - simone.machetti@epfl.ch                    --
--                                                                              --
-- Additional contributions by:                                                 --
--                 Name Surname - email (affiliation if not ESL)                --
--                                                                              --
-- Design Name:    axi2obi                                                      --
--                                                                              --
-- Project Name:   X-HEEP                                                       --
--                                                                              --
-- Language:       VHDL                                                         --
--                                                                              --
-- Description:    AXI2OBI bridge module.                                       --
--                                                                              --
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi2obi is
  generic (
    -- RISC-V interface parameters
    WordSize : integer := 32;
    AddrSize : integer := 32;

    -- Parameters of Axi Slave Bus Interface S00_AXI
    C_S00_AXI_DATA_WIDTH : integer := 32;
    C_S00_AXI_ADDR_WIDTH : integer := 32
  );
  port (
    ----------------------------
    -- RISC-V interface ports --
    ----------------------------

    gnt_i    : in  std_logic;
    rvalid_i : in  std_logic;
    we_o     : out std_logic;
    be_o     : out std_logic_vector(3 downto 0);
    addr_o   : out std_logic_vector(AddrSize - 1 downto 0);
    wdata_o  : out std_logic_vector(WordSize - 1 downto 0);
    rdata_i  : in  std_logic_vector(WordSize - 1 downto 0);
    req_o    : out std_logic;

    ----------------------------------------------
    -- Ports of Axi Slave Bus Interface S00_AXI --
    ----------------------------------------------

    -- Clk and rst signals
    s00_axi_aclk    : in  std_logic;                                              -- clock
    s00_axi_aresetn : in  std_logic;                                              -- active low reset

    -- Read address channel signals
    s00_axi_araddr  : in  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);      -- read address
    s00_axi_arvalid : in  std_logic;                                              -- read address valid
    s00_axi_arready : out std_logic;                                              -- read address ready
    s00_axi_arprot  : in  std_logic_vector(2 downto 0);                           -- not used

    -- Read data channel signals
    s00_axi_rdata   : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);      -- read data
    s00_axi_rresp   : out std_logic_vector(1 downto 0);                           -- read response
    s00_axi_rvalid  : out std_logic;                                              -- read valid
    s00_axi_rready  : in  std_logic;                                              -- read ready

    -- Write address channel signals
    s00_axi_awaddr  : in  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);      -- write address
    s00_axi_awvalid : in  std_logic;                                              -- write address valid
    s00_axi_awready : out std_logic;                                              -- write address ready
    s00_axi_awprot  : in  std_logic_vector(2 downto 0);                           -- not used

    -- Write data channel signals
    s00_axi_wdata   : in  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);      -- write data
    s00_axi_wvalid  : in  std_logic;                                              -- write data valid
    s00_axi_wready  : out std_logic;                                              -- write data ready
    s00_axi_wstrb   : in  std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);  -- not used

    -- Write response channel signals
    s00_axi_bresp   : out std_logic_vector(1 downto 0);                           -- write response
    s00_axi_bvalid  : out std_logic;                                              -- write response valid
    s00_axi_bready  : in  std_logic                                               -- write response ready
  );
end axi2obi;

architecture arch_imp of axi2obi is

  type state is (IDLE, READ1, READ2, READ3, WRITE1, WRITE2, WRITE3);
  signal currstate, nextstate : state;
  signal curr_addr, next_addr : std_logic_vector(31 downto 0);
  signal curr_wdata, next_wdata : std_logic_vector(31 downto 0);
  signal curr_rdata, next_rdata : std_logic_vector(31 downto 0);

begin

  s00_axi_rresp <= (OTHERS => '0'); -- "OKAY"
  s00_axi_bresp <= (OTHERS => '0'); -- "OKAY"

  process (s00_axi_aclk, s00_axi_aresetn)
  begin
    if(s00_axi_aclk = '1' and s00_axi_aclk 'event) then
      if(s00_axi_aresetn = '0') then
        currstate <= IDLE;
      else
        currstate <= nextstate;
      end if;
    end if;
  end process;

  process (s00_axi_aclk, s00_axi_aresetn)
  begin
    if(s00_axi_aclk = '1' and s00_axi_aclk 'event) then
      if(s00_axi_aresetn = '0') then
        curr_addr <= (others => '0');
        curr_wdata <= (others => '0');
        curr_rdata <= (others => '0');
      else
        curr_addr  <= next_addr;
        curr_wdata <= next_wdata;
        curr_rdata <= next_rdata;
      end if;
    end if;
  end process;

  addr_o  <= curr_addr;
  wdata_o <= curr_wdata;
  s00_axi_rdata <= curr_rdata;

  process (currstate, curr_addr, curr_wdata, curr_rdata, gnt_i, rvalid_i, rdata_i, s00_axi_arvalid, s00_axi_awvalid, s00_axi_wvalid, s00_axi_rready, s00_axi_bready, s00_axi_araddr, s00_axi_awaddr, s00_axi_wdata)
  begin

    nextstate  <= currstate;
    next_addr  <= curr_addr;
    next_wdata <= curr_wdata;
    next_rdata <= curr_rdata;

    we_o  <= '0';
    be_o  <= "0000";
    req_o <= '0';

    s00_axi_arready <= '0';
    s00_axi_rvalid  <= '0';
    s00_axi_awready <= '0';
    s00_axi_wready  <= '0';
    s00_axi_bvalid  <= '0';

    case currstate is

      when IDLE =>

        if(s00_axi_arvalid = '1') then
          nextstate <= READ1;
          next_addr <= s00_axi_araddr;
          s00_axi_arready <= '1';
        elsif(s00_axi_awvalid = '1' and s00_axi_wvalid = '1') then
          next_addr  <= s00_axi_awaddr;
          next_wdata <= s00_axi_wdata;
          s00_axi_awready <= '1';
          s00_axi_wready  <= '1';
          nextstate <= WRITE1;
        else
          nextstate <= IDLE;
        end if;

      when READ1 =>

        req_o <= '1';
        we_o  <= '0';
        be_o  <= "1111";

        if(gnt_i = '1') then
          nextstate <= READ2;
        else
          nextstate <= READ1;
        end if;

      when READ2 =>

        req_o <= '0';
        we_o  <= '0';
        be_o  <= "1111";

        if(rvalid_i = '1') then
          next_rdata <= rdata_i;
          nextstate  <= READ3;
        else
          nextstate <= READ2;
        end if;

      when READ3 =>

        s00_axi_rvalid <= '1';

        if(s00_axi_rready = '1') then
          nextstate <= IDLE;
        else
          nextstate <= READ3;
        end if;

      when WRITE1 =>

        req_o <= '1';
        we_o  <= '1';
        be_o  <= "1111";

        if(gnt_i = '1') then
          nextstate <= WRITE2;
        else
          nextstate <= WRITE1;
        end if;

      when WRITE2 =>

        req_o <= '0';
        we_o  <= '1';
        be_o  <= "1111";

        if(rvalid_i = '1') then
          nextstate <= WRITE3;
        else
          nextstate <= WRITE2;
        end if;

      when WRITE3 =>

        s00_axi_bvalid <= '1';

        if(s00_axi_bready = '1') then
          nextstate <= IDLE;
        else
          nextstate <= WRITE3;
        end if;

      when OTHERS =>

    end case;

  end process;

end arch_imp;
