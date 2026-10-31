"use client";

import { useEffect, useRef, useState } from "react";
import {
  AlertTriangle,
  Camera,
  CameraOff,
  Mic,
  MicOff,
  Phone,
  PhoneCall,
  PhoneOff,
  Shield,
  Sparkles,
  Video,
  X,
} from "lucide-react";
import { apiRequest } from "@/lib/api/browser-client";
import type { CallSession, Match } from "@/types/roamora";

interface LiveCallingModalProps {
  match: Match;
  currentUserId: string;
  initialCall?: CallSession | null;
  onClose: () => void;
}

export function LiveCallingModal({
  match,
  currentUserId,
  initialCall = null,
  onClose,
}: LiveCallingModalProps) {
  const [activeCall, setActiveCall] = useState<CallSession | null>(initialCall);
  const [callStatus, setCallStatus] = useState<"initiating" | "calling" | "ringing" | "connected" | "ended">("initiating");
  const [isAudioOnly, setIsAudioOnly] = useState(false);
  const [micMuted, setMicMuted] = useState(false);
  const [cameraOff, setCameraOff] = useState(false);
  const [selectedEffect, setSelectedEffect] = useState<"none" | "glow" | "sepia" | "cyber" | "soft">("none");
  const [errorMessage, setErrorMessage] = useState("");
  const [callDuration, setCallDuration] = useState(0);

  const localVideoRef = useRef<HTMLVideoElement | null>(null);
  const remoteVideoRef = useRef<HTMLVideoElement | null>(null);
  const localStreamRef = useRef<MediaStream | null>(null);
  const peerConnectionRef = useRef<RTCPeerConnection | null>(null);
  const timerRef = useRef<any>(null);

  const isIncoming = activeCall && activeCall.calleeId === currentUserId && activeCall.status === "CALLING";

  // WebRTC ICE servers configuration
  const rtcConfig: RTCConfiguration = {
    iceServers: [
      { urls: "stun:stun.l.google.com:19302" },
      { urls: "stun:stun1.l.google.com:19302" },
    ],
  };

  // Start local camera/mic stream
  async function startLocalMedia(audioOnly = false) {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: true,
        video: !audioOnly,
      });
      localStreamRef.current = stream;
      if (localVideoRef.current) {
        localVideoRef.current.srcObject = stream;
      }
      return stream;
    } catch (err: any) {
      setErrorMessage(
        "Camera/Microphone permission denied. Please allow access in browser settings.",
      );
      return null;
    }
  }

  // Initialize outbound call
  async function initiateCall(type: "AUDIO" | "VIDEO") {
    setIsAudioOnly(type === "AUDIO");
    setCallStatus("calling");
    setErrorMessage("");

    const stream = await startLocalMedia(type === "AUDIO");
    if (!stream) return;

    try {
      const pc = new RTCPeerConnection(rtcConfig);
      peerConnectionRef.current = pc;

      stream.getTracks().forEach((track) => pc.addTrack(track, stream));

      pc.ontrack = (event) => {
        if (remoteVideoRef.current && event.streams[0]) {
          remoteVideoRef.current.srcObject = event.streams[0];
          setCallStatus("connected");
        }
      };

      const offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      const call = await apiRequest<CallSession>("/calls/initiate", {
        method: "POST",
        body: JSON.stringify({
          targetUserId: match.otherUserId,
          matchId: match.id,
          callType: type,
          offer,
        }),
      });

      setActiveCall(call);

      // Handle ICE candidates
      pc.onicecandidate = (event) => {
        if (event.candidate && call.id) {
          void apiRequest(`/calls/${call.id}/candidate`, {
            method: "POST",
            body: JSON.stringify({ candidate: event.candidate }),
          });
        }
      };
    } catch (err: any) {
      setErrorMessage(err.message || "Failed to start call");
      setCallStatus("ended");
    }
  }

  // Accept incoming call
  async function acceptCall() {
    if (!activeCall) return;
    setCallStatus("connected");
    setErrorMessage("");

    const stream = await startLocalMedia(activeCall.callType === "AUDIO");
    if (!stream) return;

    try {
      const pc = new RTCPeerConnection(rtcConfig);
      peerConnectionRef.current = pc;

      stream.getTracks().forEach((track) => pc.addTrack(track, stream));

      pc.ontrack = (event) => {
        if (remoteVideoRef.current && event.streams[0]) {
          remoteVideoRef.current.srcObject = event.streams[0];
        }
      };

      if (activeCall.offer) {
        await pc.setRemoteDescription(new RTCSessionDescription(activeCall.offer));
        const answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);

        await apiRequest(`/calls/${activeCall.id}/answer`, {
          method: "POST",
          body: JSON.stringify({ answer }),
        });
      }

      pc.onicecandidate = (event) => {
        if (event.candidate && activeCall.id) {
          void apiRequest(`/calls/${activeCall.id}/candidate`, {
            method: "POST",
            body: JSON.stringify({ candidate: event.candidate }),
          });
        }
      };
    } catch (err: any) {
      setErrorMessage(err.message || "Failed to answer call");
    }
  }

  // Hang up / End call
  async function hangUp() {
    if (activeCall) {
      try {
        await apiRequest(`/calls/${activeCall.id}/end`, { method: "POST" });
      } catch {
        // Ignore
      }
    }

    if (localStreamRef.current) {
      localStreamRef.current.getTracks().forEach((t) => t.stop());
    }
    if (peerConnectionRef.current) {
      peerConnectionRef.current.close();
    }
    if (timerRef.current) {
      clearInterval(timerRef.current);
    }
    setCallStatus("ended");
    setTimeout(onClose, 800);
  }

  // Poll for answer when calling
  useEffect(() => {
    if (callStatus !== "calling" || !activeCall) return;

    const interval = setInterval(async () => {
      try {
        const res = await apiRequest<CallSession>(`/calls/active?matchId=${match.id}`);
        if (res && res.status === "ACCEPTED" && res.answer && peerConnectionRef.current) {
          if (!peerConnectionRef.current.currentRemoteDescription) {
            await peerConnectionRef.current.setRemoteDescription(new RTCSessionDescription(res.answer));
            setCallStatus("connected");
          }
        } else if (res && res.status === "ENDED") {
          setCallStatus("ended");
          clearInterval(interval);
        }
      } catch {
        // Continue polling
      }
    }, 2000);

    return () => clearInterval(interval);
  }, [callStatus, activeCall, match.id]);

  // Duration timer when connected
  useEffect(() => {
    if (callStatus === "connected") {
      timerRef.current = setInterval(() => {
        setCallDuration((d) => d + 1);
      }, 1000);
    }
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [callStatus]);

  // Toggle Mute
  function toggleMic() {
    if (!localStreamRef.current) return;
    const audioTrack = localStreamRef.current.getAudioTracks()[0];
    if (audioTrack) {
      audioTrack.enabled = !audioTrack.enabled;
      setMicMuted(!audioTrack.enabled);
    }
  }

  // Toggle Camera
  function toggleCamera() {
    if (!localStreamRef.current) return;
    const videoTrack = localStreamRef.current.getVideoTracks()[0];
    if (videoTrack) {
      videoTrack.enabled = !videoTrack.enabled;
      setCameraOff(!videoTrack.enabled);
    }
  }

  const formatTime = (secs: number) => {
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return `${m}:${s < 10 ? "0" : ""}${s}`;
  };

  const getEffectFilterStyle = () => {
    switch (selectedEffect) {
      case "glow":
        return "brightness(1.08) contrast(1.05) saturate(1.2)";
      case "sepia":
        return "sepia(0.4) contrast(1.1) brightness(0.95)";
      case "cyber":
        return "hue-rotate(330deg) saturate(1.35)";
      case "soft":
        return "blur(0.5px) contrast(0.95) brightness(1.05)";
      default:
        return "none";
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/85 backdrop-blur-md p-4 animate-in fade-in duration-200">
      <div className="bg-slate-900 border border-slate-700/60 rounded-3xl max-w-2xl w-full overflow-hidden shadow-2xl flex flex-col text-white">
        {/* Call Header */}
        <div className="p-4 bg-slate-800/80 border-b border-slate-700 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-coral flex items-center justify-center font-bold text-sm shadow">
              {match.name.slice(0, 2).toUpperCase()}
            </div>
            <div>
              <h3 className="font-bold text-sm leading-tight">{match.name}</h3>
              <span className="text-[11px] text-pink-300 flex items-center gap-1 font-medium">
                <Shield size={12} /> Privacy-Gated Match Call ·{" "}
                {callStatus === "connected" ? (
                  <span className="text-green-400 font-mono font-bold">
                    {formatTime(callDuration)}
                  </span>
                ) : callStatus === "calling" ? (
                  "Calling..."
                ) : isIncoming ? (
                  "Incoming Call..."
                ) : (
                  "Ready to Connect"
                )}
              </span>
            </div>
          </div>
          <button
            type="button"
            onClick={hangUp}
            className="text-gray-400 hover:text-white p-2 rounded-xl hover:bg-slate-700/60 transition-colors"
          >
            <X size={20} />
          </button>
        </div>

        {/* Video Stage / Media Screen */}
        <div className="relative w-full aspect-video bg-black flex items-center justify-center overflow-hidden">
          {/* Remote Video Stream */}
          <video
            ref={remoteVideoRef}
            autoPlay
            playsInline
            className="w-full h-full object-cover"
          />

          {/* Remote avatar placeholder when no remote video */}
          {callStatus !== "connected" && (
            <div className="absolute inset-0 flex flex-col items-center justify-center bg-gradient-to-b from-slate-900 via-purple-950/40 to-slate-900 p-6 text-center">
              <div className="relative">
                <div className="w-24 h-24 rounded-full bg-gradient-to-tr from-coral to-rose-400 p-1 shadow-2xl mb-4 animate-pulse">
                  <div
                    className="w-full h-full rounded-full bg-slate-800 bg-cover bg-center flex items-center justify-center text-3xl font-bold"
                    style={match.image ? { backgroundImage: `url("${match.image}")` } : undefined}
                  >
                    {!match.image && match.name.slice(0, 2).toUpperCase()}
                  </div>
                </div>
                {callStatus === "calling" && (
                  <div className="absolute -bottom-1 -right-1 p-2 bg-coral rounded-full animate-bounce shadow">
                    <PhoneCall size={16} />
                  </div>
                )}
              </div>
              <h4 className="text-xl font-bold">{match.name}</h4>
              <p className="text-xs text-gray-300 mt-1 max-w-xs">
                {callStatus === "calling"
                  ? "Ringing your match's device..."
                  : isIncoming
                  ? `${match.name} is calling you via live video!`
                  : "Tap Start Video or Audio to begin your private call."}
              </p>
            </div>
          )}

          {/* Local Camera Picture-in-Picture Preview */}
          {!isAudioOnly && (
            <div className="absolute top-4 right-4 w-32 sm:w-44 aspect-video rounded-2xl overflow-hidden border-2 border-white/40 shadow-2xl bg-slate-800 z-20">
              <video
                ref={localVideoRef}
                autoPlay
                playsInline
                muted
                style={{ filter: getEffectFilterStyle() }}
                className="w-full h-full object-cover transform -scale-x-100"
              />
              {cameraOff && (
                <div className="absolute inset-0 bg-slate-900/90 flex items-center justify-center text-xs text-gray-400">
                  Camera Off
                </div>
              )}
            </div>
          )}

          {/* Error Message banner */}
          {errorMessage && (
            <div className="absolute top-4 left-4 right-4 bg-red-600/90 backdrop-blur p-3 rounded-xl text-xs flex items-center gap-2 z-30 shadow-lg">
              <AlertTriangle size={16} className="shrink-0" />
              <span>{errorMessage}</span>
            </div>
          )}
        </div>

        {/* Visual Effects & Filter Selector */}
        {!isAudioOnly && callStatus === "connected" && (
          <div className="px-4 py-2 bg-slate-800/60 border-t border-slate-700/50 flex items-center justify-center gap-2 text-xs">
            <span className="text-[11px] text-pink-300 font-semibold flex items-center gap-1 mr-1">
              <Sparkles size={13} /> Visual Glow:
            </span>
            {(["none", "glow", "soft", "sepia", "cyber"] as const).map((eff) => (
              <button
                key={eff}
                type="button"
                onClick={() => setSelectedEffect(eff)}
                className={`px-2.5 py-1 rounded-lg text-[11px] font-bold capitalize transition-all ${
                  selectedEffect === eff
                    ? "bg-coral text-white shadow"
                    : "bg-slate-700/50 text-gray-300 hover:bg-slate-700"
                }`}
              >
                {eff}
              </button>
            ))}
          </div>
        )}

        {/* Call Controls Bar */}
        <div className="p-5 bg-slate-800/90 border-t border-slate-700 flex items-center justify-center gap-4 sm:gap-6">
          {isIncoming ? (
            <>
              <button
                type="button"
                onClick={acceptCall}
                className="px-6 py-3.5 bg-green-500 hover:bg-green-600 text-white rounded-2xl font-bold flex items-center gap-2 shadow-lg transition-transform hover:scale-105"
              >
                <Phone size={18} /> Accept Call
              </button>
              <button
                type="button"
                onClick={hangUp}
                className="px-6 py-3.5 bg-red-600 hover:bg-red-700 text-white rounded-2xl font-bold flex items-center gap-2 shadow-lg transition-transform hover:scale-105"
              >
                <PhoneOff size={18} /> Decline
              </button>
            </>
          ) : callStatus === "initiating" ? (
            <>
              <button
                type="button"
                onClick={() => void initiateCall("VIDEO")}
                className="px-6 py-3.5 bg-coral hover:bg-coral-dark text-white rounded-2xl font-bold flex items-center gap-2 shadow-lg transition-transform hover:scale-105"
              >
                <Video size={18} /> Start Video Call
              </button>
              <button
                type="button"
                onClick={() => void initiateCall("AUDIO")}
                className="px-6 py-3.5 bg-slate-700 hover:bg-slate-600 text-white rounded-2xl font-bold flex items-center gap-2 shadow-lg transition-transform hover:scale-105"
              >
                <Phone size={18} /> Audio Only
              </button>
            </>
          ) : (
            <>
              <button
                type="button"
                onClick={toggleMic}
                className={`w-12 h-12 rounded-2xl flex items-center justify-center shadow-lg transition-all ${
                  micMuted ? "bg-red-500 text-white" : "bg-slate-700 text-white hover:bg-slate-600"
                }`}
                title={micMuted ? "Unmute Mic" : "Mute Mic"}
              >
                {micMuted ? <MicOff size={20} /> : <Mic size={20} />}
              </button>

              {!isAudioOnly && (
                <button
                  type="button"
                  onClick={toggleCamera}
                  className={`w-12 h-12 rounded-2xl flex items-center justify-center shadow-lg transition-all ${
                    cameraOff ? "bg-red-500 text-white" : "bg-slate-700 text-white hover:bg-slate-600"
                  }`}
                  title={cameraOff ? "Turn Camera On" : "Turn Camera Off"}
                >
                  {cameraOff ? <CameraOff size={20} /> : <Camera size={20} />}
                </button>
              )}

              <button
                type="button"
                onClick={hangUp}
                className="w-14 h-14 bg-red-600 hover:bg-red-700 text-white rounded-2xl flex items-center justify-center shadow-xl transition-transform hover:scale-110 active:scale-95"
                title="Hang Up"
              >
                <PhoneOff size={24} />
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

