/// Command types used in the Bitcoin P2P network protocol.
/// * [version]: Initiates version negotiation between peers
/// * [verack]: Acknowledges version negotiation
/// * [addr]: Broadcasts network addresses of active peers
/// * [inv]: Advertises possession of one or more objects
/// * [sendcmpct]: Signals compact block relay preference
/// * [getdata]: Requests specific objects from a peer
/// * [notfound]: Response when requested objects aren't found
/// * [block]: Transmits a block
/// * [headers]: Transmits block headers
/// * [getheaders]: Requests block headers
/// * [mempool]: Requests contents of memory pool
/// * [checkorder]: Legacy command for merchant trade protocol
/// * [submitorder]: Legacy command for merchant trade protocol
/// * [reply]: Generic reply message
/// * [ping]: Tests connection liveness
/// * [pong]: Response to ping
/// * [reject]: Informs peer of rejected message
/// * [filterload]: Sets transaction bloom filter
/// * [filteradd]: Adds pattern to bloom filter
/// * [filterclear]: Removes bloom filter
/// * [merkleblock]: Transmits merkle block
/// * [alert]: Legacy command for network alerts
/// * [sendheaders]: Requests direct headers announcement
/// * [feefilter]: Sets minimum fee rate for transaction relay
/// * [unknown]: Represents unrecognized commands
/// * [getaddr]: Requests network addresses of active peers
enum MessageCommand {  
  version,
  verack,
  addr,
  getaddr,
  inv,
  sendcmpct,
  getdata,
  notfound,
  block,
  headers,
  getheaders,
  mempool,
  checkorder,
  submitorder,
  reply,
  ping,
  pong,
  reject,
  filterload,
  filteradd,
  filterclear,
  merkleblock,
  alert,
  sendheaders,
  feefilter,
  getcfilters,
  cfilter,
  unknown
}