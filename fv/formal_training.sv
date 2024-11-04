

////////////////////////////////////////////////////////////////////////////////
// 1. ARBITER
////////////////////////////////////////////////////////////////////////////////

cover reqs - pokriti sve req signale da li mogu da se dese i da li svi mogu da se dese odjednom 
cover gnts - da li svaki gnt moze da se desi, da li se gnt moze biti na visokom nivou ako je valid na nuli
cover reqs x gnts - 

assert $onehot(gnt)
 
assert fairness
assert no starvation

assume ako se podigne req, on ostaje stabilan sve dok ne dobije gnt


asm_stable_req: assume property(req && !gnt |=> req);

ast_onehot_gnt: assert property($onehot(gnt));
ast_no_starvation: assert property(req |-> s_eventually(gnt));
ast_gnt_happens: assert property(req |-> gnt != 0)
ast_no_gnt: assert property(!req |-> !gnt);



req0, req1

should_req1_gnt

always @(posedge clk) begin
  if(reset)
    should_req1_gnt <= 0;
  else begin
    if(gnt[req1])
      should_req1_gnt <= 0
    else if(req1 && gnt[req0])
      should_req1_gnt <= 1
    end
end
ast_fairness: assert property(gnt[req0] |-> !should_req1_gnt);


logic[N-1:0] req, gnt, last_grant_q;


always @(posedge clk) begin
  if(reset)
    last_grant_q <= 0;
  else begin
    last_grant_q <= gnt;
    // if(req == last_grant_q)
  end
end


ast_fairness2: assert property((req == last_grant_q) && ($onehot(req) == 0) |-> gnt != req);

ast_fairness3: assert property(req_i && gnt_i == req_i && ($onehot(req) == 0) |=> $changed(gnt) );

ast_fairness3b: assert property($onehot(req) |-> req == gnt);

ast_fairness4: assert property(req[i] == gnt[i] && $changed(req) |=> gnt != req);

// Javi se req i nek je bio onehot, dobija u tom taktu gnt. U sledecem taktu se javi stari req i neki novi.
// Novi mora dobiti gnt, a moze biti i luft izmedju.
// Kako osigurati da ako postoji pauza izmedju da ce novi dobiti gnt?


ast_fairness5: assert property(gnt[i] |=> !gnt[i] until (req[i] && $onehot(req)) || (gnt > 0 && !gnt[i]));

request[i] && $onehot(request) |-> gnt[i]; // -> Solo Request
gnt[i] |=> gnt[i] == 'b0 || (request[i] > 'b0 && $onehot(request)); // -> Next cycle fairness
gnt[i] |=> (gnt[i] == 'b0) until $past(gnt > 'b0 && gnt[i] == 'b0) || (request[i] > 'b0 && $onehot(request)); // -> Fairness all the way!


////////////////////////////////////////////////////////////////////////////////
// 2. Packet processor
////////////////////////////////////////////////////////////////////////////////

// Does this constrain the system in a way where it is not possible to happen: (start && valid && ready && !last) ##[1:$] last && valid ##[1:$] ready

// If first valid is asserted start must be asserted 

// QUESTIONS
// Could start, valid, last happen in one cycle?
// Should start last for only one cycle?

// ASSUMPTIONS

// Valid stays stable until ready
// Start/valid can't happen multiple times before last/valid is asserted
// Last/valid can only be asserted if the packet is ingressing and there was previously start/valid

// Protocol definition
asm_valid_stability: assume property(valid && !ready |=> valid);
asm_start_valid_stability: assume property(valid && !ready |=> $stable(start));
asm_last_valid_stability: assume property(valid && !ready |=> $stable(last));

asm_start_valid: assume property(start && valid && ready && !last |=> !(start && valid) until_with (last && valid & ready));
asm_last_valid: assume property(last && valid && ready && !start |=> !(last && valid) until_with (start && valid & ready));

asm_last_valid: assume property($rose(reset) |-> !(last && valid) until (start && valid));


// CHECKS
// Assumptions can serve as assertions on the output interface
// Protocol definition
ast_valid_stability: assert property(valid && !ready |=> valid);
ast_start_valid_stability: assert property(valid && !ready |=> $stable(start));
ast_last_valid_stability: assert property(valid && !ready |=> $stable(last));


ast_start_valid: assert property(start && valid && ready && !last |=> !(start && valid) until_with (last && valid & ready));
ast_last_valid: assert property(last && valid && ready && !start |=> !(last && valid) until_with (start && valid & ready));

ast_last_valid: assert property($rose(reset) |-> !(last && valid) until (start && valid));

// End-to-end checks
ast_last_o: assert property($rose(reset) |-> !(last_o && valid_o) until (last_i && valid_i && ready_i));
ast_start_o: assert property($rose(reset) |-> !(start_o & valid_o) until (start_i && valid_i && ready_i));

// until_with -> last_o can not happen in the same cycle as last_i
// until -> last_o can happen in the same cycle as last_i
ast_last_o: assert property((last_o && valid_o && ready_o) |=> !(last_o && valid_o) until_with (last_i && valid_i && ready_i));

ast_start_live: assert property((start_i && valid_i) |=> s_eventually (start_o & valid_o));
ast_last_live: assert property((last_i && valid_i) |=> s_eventually (last_o & valid_o));

// COVERAGE
// Applied both on input and output
cov_single_txn: cover property(start && valid && ready && last);

cov_start: cover property(start && valid);
cov_last: cover property(last && valid);
cov_last_start: cover property(last && valid ##1 ready ##1 start && valid);




// cover start, valid
// cover start, valid, last
// cover last
// cover stream of data, single data
// cover last -> start sequence 

////////////////////////////////////////////////////////////////////////////////
// 3. AXI, Xbar
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
// ASSERT
////////////////////////////////////////////////////////////////////////////////
// Handshake process
// Can be applied to every channel
ast_vld_stable_before_rdy: assert property(valid && !ready |=> valid); // ok
// ast_rdy_stable_before_vld: assert property(ready && !valid |=> ready);

ast_info_stable_before_rdy: assert property(valid && !ready |=> $stable(info)); //ok
// Write channel

// For signals like awvalid which can happen anytime, we only check the case if asserted when they can be asserted again
// No left side from the cycle when they were asserted
ast_no_awvalid: assert property(awvalid && awready |=> !(awvalid) until_with (bvalid && bready)); 

ast_no_wvalid: assert property(wvalid && wlast & wready |=> !(wvalid) until (awvalid)); 
ast_no_wvalid2: assert property($rose(reset) |-> !(wvalid) until (awvalid)); 


ast_no_bvalid1: assert property(awvalid || wvalid |-> !bvalid); 

ast_no_bvalid2: assert property(bvalid |=> !bvalid until_with wvalid && wready && wlast); 
ast_no_bvalid3: assert property($rose(reset) |-> !bvalid until_with wvalid && wready && wlast); 


//wlast
ast_wlast1: assert property(last_wdata_flag |-> wlast); 
ast_wlast2: assert property(awvalid |-> !wlast);
// valid wlast can not happen until new transaction is initiated
ast_wlast2: assert property(wlast && wvalid && wready |=> !(wlast && wvalid) until (awvalid)); 
ast_wlast3: assert property($rose(reset) |=> !(wlast && wvalid) until (awvalid)); 

ast_wlast3: assert property(bvalid |-> !wlast);

ast_w_no_err_code: assert property(bresp == 0)

// Read channel

ast_arvalid: assert property();

// Address accepted, from next cycle there can be no new transactions until the last data from current has been accepted
ast_no_arvalid: assert property(arvalid && arready |=> !(arvalid) until_with (rvalid && rready && rlast)); 


ast_no_rvalid: assert property(arvalid || arready |-> !rvalid);

ast_no_rvalid2: assert property(rvalid |=> (!rvalid) until_with (arvalid && arready)); 
ast_no_bvalid3: assert property($rose(reset) |-> (!rvalid) until_with (arvalid && arready)); 

ast_rlast: assert property(last_rdata_flag |-> rlast); 
// until 
ast_rlast2: assert property(rlast && rvalid && rready |=> !(rlast && rvalid) until_with (arvalid && arready)); 
ast_rlast3: assert property($rose(reset) |=> !(rlast && rvalid) until_with (arvalid && arready)); 

ast_r_no_err_code: assert property(rresp == 0)

////////////////////////////////////////////////////////////////////////////////
// COVER
////////////////////////////////////////////////////////////////////////////////

// Can be applied to every channel
cov_vld_before_rdy: cover property(valid && !ready);
cov_rdy_before_vld: cover property(ready && valid);
cov_vld_with_rdy: cover property(ready && valid);

cov_wlast: cover property(wlast)
cov_rlast: cover property(rlast)


////////////////////////////////////////////////////////////////////////////////
// 3. Processing system
////////////////////////////////////////////////////////////////////////////////
/
// INPUT
  1. When busy is set timer is reseted and start_send is deasserted
  2. start, end -> busy
  3. busy |-> $stable(time_match) && time_match > 0 
  4. start, end is pulse

// OUTPUT
  1. busy -> !start_send && !end_send
  2. start_send, end_send, irq_send |-> !busy
  3. timer == time_match |=> irq_send
  4. timer is reseted upon busy or irq_send
  5. during start_send - end_send timer is 0, not counting
  6. timer is counting cycles when !busy and !sending, when block is idle, can, but is not sending any data
  7. start_send can be asserted only after irq_send

  8. timer == time_match |=> irq_send && timeer == 0 && !busy |=> start_send

  9. start || end |-> !(start_send || end_send)

  10. busy && timer == 0 && start && end && time_match == TIME |=> !busy && timer counts |=> timer == time_match 

*/
////////////////////////////////////////////////////////////////////////////////
// ASSUMPTIONS
////////////////////////////////////////////////////////////////////////////////

// INPUT
asm_busy1: assume property(irq_send |-> !busy until_with end_send);

asm_start1: assume property(start_i |-> busy);
// asm_start2: assume property(!busy |-> !start_i);
asm_start3: assume property(start_i |=> !start_i)

asm_start_end: assume property(start_i |-> !end_i);
asm_start_end2: assume property(start_i |=> !(start_i) until_with (end_i));

asm_start_end4: assume property(end_i |=> !(end_i) until_with (start_i));
asm_start_end3: assume property($rose(reset) |-> !(end_i) until_with (start_i));

asm_end1: assume property(end_i |-> busy);
asm_end2: assume property(start_i |=> s_eventually end_i);
asm_end3: assume property(end_i |=> !end_i)
// asm_end4: assume property(!busy |-> !end_i);

time_match: assume property(busy |-> $stable(time_match));
time_match2: assume property(time_match > 0);


// OUTPUT

ast_irq_send1: assert property(timer >= timer_match |=> irq_send);
ast_irq_send2: assert property(irq_send |-> !busy);

ast_start_send1: assert property(irq_send |=> start_send);
ast_start_send2: assert property(start_send |-> $past(irq_send));

asm_start_send3a: assume property(start_send |=> !(start_send) until_with (irq_send));
asm_start_send3b: assume property($rose(reset) |-> !(start_send) until_with (irq_send));
asm_start_send3c: assume property(start_send |=> !(start_send) until_with (end_send));
// ast_start_send2b: assert property(!irq_send |-> !start_send);
// ast_start_send3: assert property(start_send |-> !busy);


asm_start_end1: assume property(end_send |=> !(end_send) until_with (start_send));
asm_start_end2: assume property($rose(reset) |-> !(end_send) until_with (start_send));

ast_end_send1: assert property(start_send |=> s_eventually end_send);
// ast_end_send2: assert property(end_send |-> !busy);

ast_timer1: assert property(timer >= time_match |=> timer == 0);
ast_timer2: assert property(busy |-> timer == 0);
// ast_timer3: assert property(send_irq |=> timer == 0);
ast_timer4: assert property(timer >= time_match |=> timer == 0 until_with (end_send));


////////////////////////////////////////////////////////////////////////////////
// AXI stream DUT
////////////////////////////////////////////////////////////////////////////////


// INPUT
1. Once error is asserted it will remain stable
2. If last there can not be start until packet_send
3. Packet_send can be asserted if packet has egressed
4. last => packet_send => start
5. 



asm_valid1a: assume property(valid && last |=> !(valid) until_with (packet_send));

asm_valid1b: assume property(packet_send |=> !(valid) until (start && valid));

asm_valid2: assume property($rose(reset) |-> !(valid) until_with (packet_send));

asm_start1: assume property(start && valid |=> !(start && valid) until_with packet_send);
asm_start1a: assume property($rose(reset) |-> !(start && valid) until_with packet_send);
// asm_start2: assume property(start |-> !packet_send);


asm_last1: assume property(start && valid |-> s_eventually last && valid);
asm_last2: assume property(last && valid |=> !(last && valid) until (start && valid));
asm_last2a: assume property($rose(reset) |-> !(last && valid) until (start && valid));

// asm_err: assume property(error && valid ##1 valid |=> error);
// asm_err: assume property(error && valid |=> !(valid && !error) until !valid);
// Error must be stable 
asm_err: assume property(error && valid |=> !valid until error && valid);

ast_packet_send: assert property(packet_send |=> !(packet_send) until_with (tvalid && tlast && tready));



// OUTPUT


// wrong assumption
// ast_tvalid2a: assert property(tvalid |-> !valid);
// ast_tvalid2b: assert property(tvalid |-> !active_ingress);
// ast_tvalid: assert property($rose(reset) |-> tvalid until_with valid && last);


ast_tvalid_stability: assert property(tvalid && !tready |=> tvalid);
// 
// Always check both must/ must not!
// must not/could something happen
ast_tvalid1: assert property(tvalid |-> fifo_data_cnt > 0);
// must happen on interface
ast_tvalid_live: (fifo_data_cnt > 0 |-> s_eventually(tvalid));
// ast_tvalid2: assert property(tvalid && (ingress_data_cnt[M-1:2] == 0) |-> ingress_complete);

// ast_tvalid1: assert property(tvalid && !ingress_complete |-> ingress_data_cnt[M-1:2] - 1 > 0);
// ast_tvalid2: assert property(tvalid && ingress_complete |-> ingress_data_cnt > 0);

// ast_tvalid2: assert property(tvalid |-> (ingress_data_cnt[M-1:2] + |ingress_data_cnt[1:0]) > 0);

ast_tlast_stability: assert property(tvalid && !tready |=> $stable(tlast));
ast_tdata: assert property(tvalid && !tready |=> $stable(tdata));


// ast_terror1: assert property(terror && tvalid && !last |=> terror);
ast_terror_stability: assert property(terror && tvalid |=> !(tvalid) until (terror && tvalid));
ast_terror_stability2: assert property(terror && tvalid |=> terror || !tvalid);

ast_terror1: assert property(tvalid && ingress_error && (egress_data_cnt >= erroneous_data_cnt[M-1:2]) |-> (terror));
ast_terror2: assert property(tvalid && terror |-> (egress_data_cnt >= erroneous_data_cnt[M-1:2]));

ast_tlast: assert property(ingress_complete && (egress_data_cnt == (ingress_data_cnt[M-1:2] + |ingress_data_cnt[1:0]) - 1) && tvalid |-> tlast);

1001 - 9
0010 - 2 
|01  - 1 
// ast_terror: assert property(tvalid && ingress_error |-> (terror) until_with (tlast && tvalid));







////////////////////////////////////////////////////////////////////////////////
// AUX LOGIC
////////////////////////////////////////////////////////////////////////////////

logic[N-1:0][31:0] fifo;
logic[M-1:0] ingress_data_cnt, egress_data_cnt, fifo_data_cnt;

logic active_ingress;
logic ingress_complete;
logic ingress_error;
logic erroneous_data_cnt;


// always @(posedge clk) begin
//   if(reset)
//   else begin
//   end
// end

// register when ingress is completed
// if it is not then there must be at least 4 valids for 1 valid
// if it is then then it can be less than 4
// Think about all things you should register from input to help you write properties on the output
// Ingress and Egress process are independent, you can have eggress while the packets are still ingressing

// Ingress data byte comming one cycle later it will be written into fifo and ready to be egressed

always @(posedge clk) begin
  if(reset)
    active_ingress <= 0;
    end_seen <= 0;
  else begin

    if((start && valid) && !last) 
      active_ingress <= 1;
    else if (active_ingress && valid && last)
      active_ingress <= 0;
  end
end

// It is important to know from which byte error occured 
always @(posedge clk) begin
  if(reset)
    ingress_error <= 0;
    erroneous_data_cnt <= 0;
  else begin

    if(tvalid & tlast && tready)
      ingress_error <= 0;
    else if(ingress_error == 0 && error && valid)
      ingress_error <= 1;
      // previous value 4
      erroneous_data_cnt <= ingress_data_cnt;
  end
end


always @(posedge clk) begin
  if(reset)
    ingress_complete <= 0;
  else begin

    if(packet_send)
      ingress_complete <= 0;
    else if(start && valid && last)
      ingress_complete <= 1;
    else if(active_ingress && valid && last)
      ingress_complete <= 1;

  end
end

// Ingress count
always @(posedge clk) begin
  if(reset)
    ingress_data_cnt <= 0;
    egress_data_ready <= 0;

  else begin
    egress_data_ready <= 0;
    // valid data ingressing
    if(packet_send)
      ingress_data_cnt <= 0;

    else if(valid)
      ingress_data_cnt <= ingress_data_cnt + 1;

      if((ingress_data_cnt[1:0] == 3 && valid) || (valid && last))
        egress_data_ready <= 1;
  end
end

// Egress count
always @(posedge clk) begin
  if(reset)
    egress_data_cnt <= 0;

  else begin
    // valid data egressing
    if(packet_send)
      egress_data_cnt <= 0;
    else if(tvalid && tready)
      egress_data_cnt <= egress_data_cnt + 1;
  end
end

// Fifo count
always @(posedge clk) begin
  if(reset)
    fifo_data_cnt <= 0;

  else begin
    // valid data egressing
    if(packet_send)
      fifo_data_cnt <= 0;
    else begin

      if(egress_data_ready)
        fifo_data_cnt <= fifo_data_cnt + 1;

      if(tvalid && tready)
        fifo_data_cnt <= fifo_data_cnt - 1;
    end
  end
end

////////////////////////////////////////////////////////////////////////////////
// Cache controller
////////////////////////////////////////////////////////////////////////////////
// Parameters, datatypes and signal definitions

typedef struct packed
  {
    logic [ADDR_LEN-1:0] address;
    logic [OPCODE_LEN-1:0] opcode;
    logic [TRANS_ID_LEN-1:0] trans_id;
  } req_payld_type;

typedef struct packed
  {
    logic hit;
    logic dirty;
    logic alocate;
    logic evict;
    logic [ADDR_LEN-1:0] address;
    logic [TRANS_ID_LEN-1:0] trans_id;
  } resp_payld_type;

typedef struct packed
  {
    logic allocation_done;
    logic eviction_done;
    logic [ADDR_LEN-1:0] address;
    logic [TRANS_ID_LEN-1:0] trans_id;
  } resp_evict_payld_type;

typedef struct packed
  {
    logic valid;
    logic ready;
    req_payld_type  payld;
  } req_if_type;

typedef struct packed
  {
    logic valid;
    logic ready;
    resp_payld_type  payld;
  } resp_if_type;

typedef struct packed
  {
    logic valid;
    logic ready;
    resp_evict_payld_type  payld;
  } resp_evict_if_type;

req_if_type req_if;
resp_if_type resp_if;
resp_evict_if_type resp_evict_if;

// Pick any payload and be stable for the entire test case
req_payld_ndc req_payld_ndc;
asm_payld_ndc_stability: assume property($stable(req_payld_ndc));

// If chosen(by free variable (ndc)) transaction id is on the request if and is valid, then its content must match the one from free variable
asm_req_payld: assume property(
  req_if.valid
  && req_if.payld.trans_id == req_payld_ndc.trans_id 
  |->
  req_if.payld == req_payld_ndc;
  );

// When chosen transaction is being processed then trigger the checks
logic check_active;
assign check_active = (resp_if.payld.trans_id == req_payld_ndc.trans_id);

logic chosen_trans_outstanding;
always @(posedge clk) begin
  if(reset)
    chosen_trans_outstanding <= 1'b0;
  else
    if(req_if.valid && req_if.ready && (req_if.payld.trans_id == req_payld_ndc.trans_id))
      chosen_trans_outstanding <= 1'b1;
    else if(resp_if.valid && resp_if.ready && (resp_if.payld.trans_id == req_payld_ndc.trans_id))
      chosen_trans_outstanding <= 1'b0;
end

// Store allocation and eviction events
logic allocation_event, eviction_event;
always @(posedge clk) begin
  if(reset)
    allocation_event <= 1'b0;
    eviction_event <= 1'b0;
  else
    if(resp_if.valid && resp_if.ready && (resp_if.payld.allocate))
      allocation_event <= 1'b1;
    else if(resp_evict_if.valid && resp_evict_if.ready && (resp_evict_if.payld.allocation_done))
      allocation_event <= 1'b0;

    if(resp_if.valid && resp_if.ready && (resp_if.payld.evict))
      eviction_event <= 1'b1;
    else if(resp_evict_if.valid && resp_evict_if.ready && (resp_evict_if.payld.eviction_done))
      eviction_event <= 1'b0;
end


//------------------------------------------
// INPUT
//------------------------------------------
///////////////////////////////////////
// REQUEST IF
///////////////////////////////////////

// 1. Request is a valid + payld + ready interface
  ast_req_valid_stability: assert property(req_if.valid && !req_if.ready |=> req_if.valid);
  ast_req_payld_stability: assert property(req_if.valid && !req_if.ready |=> $stable(req_if.payld));

2. Request payld has the following fields:
- ADDRESS
- OPCODE
- TRANSCATION ID

// 3. Address needs to be % 4 == 0

ast_address_allignment: assert property(req_if.payld.address[1:0] == 0);

4. Legal values for OPCODE:
- MakeInvalid -> Invalidate cacheline
- CleanInvalid -> Write DIRTY Cacheline downstream and invalidate cacheline
- CleanShared -> Write DIRTY Cacheline downstream
- Write -> Allocate cacheline to CACHE
- Read -> Read Cacheline from Cache

5. We must not have multiple outstanding requests for the same address/cacheline. 
Meaning, cache process needs to finish before sending a new request for that particular cacheline!
// Pick any two outstanding requests and make sure that they not have the same target cacheline 

6. Transaction ID represents the ID of the transaction!

7. Transaction ID is unique!
//-----------------------------------------------
// OUTPUT
//-----------------------------------------------

///////////////////////////////////////////
// RESPONSE IF
///////////////////////////////////////////

// 1. Response is a valid + payld + ready interface

  ast_resp_valid_stability: assert property(resp_if.valid && !resp_if.ready |=> resp_if.valid);
  ast_resp_payld_stability: assert property(resp_if.valid && !resp_if.ready |=> $stable(resp_if.payld));

2. Response payld has the following fields:
- HIT
- DIRTY
- ALLOCATE
- EVICT
- ADDRESS
- TRANSACTION ID

// 3. Response always comes after request, after an undefined time
  ast_resp_after_req1a: assert property(resp_if.valid && resp_if.ready |=> !(resp_if.valid) until_with (req_if.valid && req_if.ready));
  ast_resp_after_req1b: assert property($rose(reset) |-> !(resp_if.valid) until_with (req_if.valid && req_if.ready));

4. One request results in one response

EVICT - WRITE BACK

5. Some general rules for the payld:
- HIT can be set or not set without any constraints

// - DIRTY must not be set in a case of MISS

ast_miss: assert property(check_active && !response.payld.hit |-> !response.payld.dirty);

// - MakeInvalid -> Allocation and eviction must not happen as we are just invalidating cacheline

// Req and resp must not happen in the same cycle
// REQ - RESP problem
// Request must be stored and once processed this should hold
// Request are stored on valid ready handshake
ast_make_invalid: assert property(check_active && request.payld.opcode.make_invalid |-> !(response.payld.allocate || response.payld.evict));

// - CleanInvalid -> No Allocation should take place, as this is not an allocation opcode

ast_clean_invalid1: assert property(check_active && request.payld.opcode.clean_invalid |-> !(response.payld.allocate));

// - CleanInvalid -> If we HIT on a dirty cacheline, we must set EVICT

ast_clean_invalid2: assert property(check_active && request.payld.opcode.clean_invalid && hit && dirty |-> (response.payld.evict));

// - CleanInvalid -> If we HIT on a clean cacheline, we must not set EVICT

// DONE
ast_clean_invalid3: assert property(check_active && req_if.payld.opcode == CLEAN_INVALID && resp_if.payld.hit && !resp_if.payld.dirty |-> !(resp_if.payld.evict));

// - CleanInvalid -> If we MISS on a cacheline, we must not see an eviction

ast_clean_invalid4: assert property(check_active && request.payld.opcode.clean_invalid && !hit |-> !(response.payld.evict));

// - CleanShared -> No Allocation should take place, as this is not an allocation opcode

ast_clean_shared1: assert property(check_active && request.payld.opcode.clean_shared |-> !(response.payld.allocate));

// - CleanShared -> If we HIT on a dirty cacheline, we must set EVICT

ast_clean_shared2: assert property(check_active && request.payld.opcode.clean_shared && hit && dirty |-> (response.payld.evict));
// - CleanShared -> If we HIT on a clean cacheline, we must not set EVICT

ast_clean_shared3: assert property(check_active && request.payld.opcode.clean_shared && hit && !dirty |-> !(response.payld.evict));

// - CleanShared -> If we MISS on a cacheline, we must not see an eviction

ast_clean_shared4: assert property(check_active && request.payld.opcode.clean_shared && !hit |-> !(response.payld.evict));

- Write -> If we HIT on a cacheline, we must not see an eviction

// If it is a hit then this cache line will be updated, there is no need for memory load?
- Write -> If we HIT on a cacheline, we must see an allocation
- Write -> If we MISS on a cacheline, we could see an allocation or not
- Write -> If we MISS on a cacheline, we could see an eviction or not

// Cache denies allocation, writing to cache, cache line protected
// - Write -> If we MISS on a cacheline and we do not expect allocation, we must not see an eviction/write back

ast_write_miss_no_allocation: assert property(write && !allocation && !hit |-> !evict);

- Write -> If we MISS on a cacheline and we expect an allocation, we could see an eviction or not

- Read -> No Allocation should take place, as this is not an allocation opcode
- Read -> No eviction should take place, as this opcode cannot produce an eviction

ast_read_no_allocation: assert property(read |-> !allocation);
ast_read_no_eviction: assert property(read |-> !evict);


6. Address must match one of the outstanding requests
7. Transaction ID must match one of the outstanding requests Transaction ID

//////////////////////////////////////////////////
// RESPONSE EVICT IF Active during communication with memory
//////////////////////////////////////////////////
// 

1. Response evict is a valid + payld + ready interface

  ast_resp_evict_valid_stability: assert property(valid && !ready |=> valid);
  ast_resp_evict_payld_stability: assert property(valid && !ready |=> $stable(payld));

2. Response evict payld has the following fields:
- ALLOCATION_DONE
- EVICTION_DONE
- ADDRESS
- TRANSACTION ID

3. Response Eviction must always come after Response

  ast_resp_evict_valid_if1a: assert property(response_evict.valid && response_evict.ready |=> !(response_evict.valid) until_with (response.valid && response.ready));
  ast_resp_evict_valid_if1b: assert property($rose(reset) |-> !(response_evict.valid) until_with (response.valid && response.ready));

4. Response eviction must appear only if either ALLOCATION or EVICT was set at Response
  // store allocation or eviction event and check
  ast_resp_evict_valid_if2a: assert property(response_evict.valid |-> allocation_event || evict_event);
  ast_resp_evict_valid_if2b: assert property(allocation_event || evict_event |=> s_eventually (response_evict.valid));

5. Response eviction must not appear if neither ALLOCATION nor EVICT was set at response
  ast_resp_evict_valid_if3: assert property(!(allocation_event || evict_event) |=> !(response_evict.valid));

// DONE
// 6. ALLOCATION_DONE must be set just if allocation was set at Response
  ast_allocation_done1a: assert property(!(allocation_event) |-> !(resp_evict_if.valid && resp_evict_if.payld.allocation_done));
  ast_allocation_done1b: assert property(resp_evict_if.valid && resp_evict_if.ready && resp_evict_if.payld.allocation_done |-> allocation_event);


7. EVICTION_DONE must be set just if eviction was set at Response
  ast_allocation_done: assert property(!(allocation_event || evict_event) |-> !(resp_evict_if.payld.allocation_done));

// 
8. ADDRESS must match the address from the request, if ALLOCATION_DONE is set and EVICTION_DONE is not set

9. ADDRESS must not match the address from the request, if ALLOCATION_DONE is set and EVICTION_DONE is set

10. ADDRESS must match the address from the request, if ALLOCATION_DONE is not set
11. Transaction ID must match Transaction ID from Response

//--------------------------------------------------------------
// GENERAL RULES
//---------------------------------------------------------------

Steps for a single cache process looks like this:

Request -> Response -> (Response Evict, but this is conditional, it could appear, depends on the payld values at response)
We must not have multiple outstanding cache processes for a given address!

ast_outstanding_reqs1: assert property(chosen_trans_outstanding && req_if.valid |-> !(req_if.payld.trans_id == req_payld_ndc.trans_id));
ast_outstanding_reqs2: assert property(chosen_trans_outstanding && req_if.valid |-> !(req_if.payld.address == req_payld_ndc.address));
ast_outstanding_reqs3: assert property(chosen_trans_outstanding |-> s_eventually !chosen_trans_outstanding);

There is just ONE channel on each interface
So we cannot see multiple Requests at the same time
So we cannot see multiple Responses at the same time
So we cannot see multiple Response Evicts at the same time
Responses can come out of order!
So, it can be that we have the following:
Request1 -> Request2 -> Request3 -> Response3 -> Request4 -> Response4 -> Request5 -> Response1
However, for the given cacheline/address we need to follow the defined sequence (Request -> Response -> (Response Evict))




