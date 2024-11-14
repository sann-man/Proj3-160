configuration TransportC{
    provides interface Transport
}
implementation{

    components new TimerMilliC() as timeoutTimer;

    Transport.timeoutTimer -> timeoutTimer;
}