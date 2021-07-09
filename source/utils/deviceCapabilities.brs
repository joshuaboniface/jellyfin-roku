'Device Capabilities for Roku.
'This will likely need further tweaking

function getDeviceCapabilities() as object

    return {
        "PlayableMediaTypes": [
            "Audio",
            "Video"
        ],
        "SupportedCommands": [],
        "SupportsPersistentIdentifier": false,
        "SupportsMediaControl": false,
        "DeviceProfile": getDeviceProfile()
    }
end function


function getDeviceProfile() as object

    'Check if 5.1 Audio Output connected
    maxAudioChannels = 2
    di = CreateObject("roDeviceInfo")
    if di.GetAudioOutputChannel() = "5.1 surround"
        maxAudioChannels = 6
    end if

    return {
        "MaxStreamingBitrate": 120000000,
        "MaxStaticBitrate": 100000000,
        "MusicStreamingTranscodingBitrate": 192000,
        "DirectPlayProfiles": GetDirectPlayProfiles(),
        "TranscodingProfiles": [
            {
                "Container": "aac",
                "Type": "Audio",
                "AudioCodec": "aac",
                "Context": "Streaming",
                "Protocol": "http",
                "MaxAudioChannels": StrI(maxAudioChannels) ' Currently Jellyfin server expects this as a string
            },
            {
                "Container": "mp3",
                "Type": "Audio",
                "AudioCodec": "mp3",
                "Context": "Streaming",
                "Protocol": "http",
                "MaxAudioChannels": "2"
            },
            {
                "Container": "mp3",
                "Type": "Audio",
                "AudioCodec": "mp3",
                "Context": "Static",
                "Protocol": "http",
                "MaxAudioChannels": "2"
            },
            {
                "Container": "aac",
                "Type": "Audio",
                "AudioCodec": "aac",
                "Context": "Static",
                "Protocol": "http",
                "MaxAudioChannels": StrI(maxAudioChannels) ' Currently Jellyfin server expects this as a string
            },
            {
                "Container": "ts",
                "Type": "Video",
                "AudioCodec": "aac",
                "VideoCodec": "h264",
                "Context": "Streaming",
                "Protocol": "hls",
                "MaxAudioChannels": StrI(maxAudioChannels) ' Currently Jellyfin server expects this as a string
                "MinSegments": "1",
                "BreakOnNonKeyFrames": true
            },
            {
                "Container": "mp4",
                "Type": "Video",
                "AudioCodec": "aac,opus,flac,vorbis",
                "VideoCodec": "h264",
                "Context": "Static",
                "Protocol": "http"
            }
        ],
        "ContainerProfiles": [],
        "CodecProfiles": [
            {
                "Type": "VideoAudio",
                "Codec": "aac",
                "Conditions": [
                    {
                        "Condition": "Equals",
                        "Property": "IsSecondaryAudio",
                        "Value": "false",
                        "IsRequired": false
                    }
                ]
            },
            {
                "Type": "Video",
                "Codec": "h264",
                "Conditions": [
                    {
                        "Condition": "EqualsAny",
                        "Property": "VideoProfile",
                        "Value": "high|main|baseline|constrained baseline",
                        "IsRequired": false
                    },
                    {
                        "Condition": "LessThanEqual",
                        "Property": "VideoLevel",
                        "Value": "51",
                        "IsRequired": false
                    }
                ]
            }
        ],
        "SubtitleProfiles": [
            {
                "Format": "vtt",
                "Method": "External"
            },
            {
                "Format": "srt",
                "Method": "External"
            },
            {
                "Format": "ttml",
                "Method": "External"
            }
        ]
    }
end function


function GetDirectPlayProfiles() as object

    mp4Video = "h264"
    mp4Audio = "mp3,pcm,lpcm,wav"
    mkvVideo = "h264,vp8"
    mkvAudio = "mp3,pcm,lpcm,wav"
    audio = "mp3,pcm,lpcm,wav"

    di = CreateObject("roDeviceInfo")

    'Check for Supported Video Codecs
    if di.CanDecodeVideo({ Codec: "hevc" }).Result = true
        mp4Video = mp4Video + ",h265"
        mkvVideo = mkvVideo + ",h265"
    end if

    if di.CanDecodeVideo({ Codec: "vp9" }).Result = true
        mkvVideo = mkvVideo + ",vp9"
    end if

    ' Check for supported Audio
    if di.CanDecodeAudio({ Codec: "ac3" }).result
        mkvAudio = mkvAudio + ",ac3"
        mp4Audio = mp4Audio + ",ac3"
        audio = audio + ",ac3"
    end if

    if di.CanDecodeAudio({ Codec: "wma" }).result
        audio = audio + ",wma"
    end if

    if di.CanDecodeAudio({ Codec: "flac" }).result
        mkvAudio = mkvAudio + ",flac"
        audio = audio + ",flac"
    end if

    if di.CanDecodeAudio({ Codec: "alac" }).result
        mkvAudio = mkvAudio + ",alac"
        mp4Audio = mp4Audio + ",alac"
        audio = audio + ",alac"
    end if

    if di.CanDecodeAudio({ Codec: "aac" }).result
        mkvAudio = mkvAudio + ",aac"
        mp4Audio = mp4Audio + ",aac"
        audio = audio + ",aac"
    end if

    if di.CanDecodeAudio({ Codec: "opus" }).result
        mkvAudio = mkvAudio + ",opus"
    end if

    if di.CanDecodeAudio({ Codec: "dts" }).result
        mkvAudio = mkvAudio + ",dts"
        audio = audio + ",dts"
    end if

    if di.CanDecodeAudio({ Codec: "wmapro" }).result
        audio = audio + ",wmapro"
    end if

    if di.CanDecodeAudio({ Codec: "vorbis" }).result
        mkvAudio = mkvAudio + ",vorbis"
    end if

    if di.CanDecodeAudio({ Codec: "eac3" }).result
        mkvAudio = mkvAudio + ",eac3"
    end if

    return [
        {
            "Container": "mp4,m4v,mov",
            "Type": "Video",
            "VideoCodec": mp4Video,
            "AudioCodec": mp4Audio
        },
        {
            "Container": "mkv,webm",
            "Type": "Video",
            "VideoCodec": mkvVideo,
            "AudioCodec": mkvAudio
        },
        {
            "Container": audio,
            "Type": "Audio",
        }
    ]

end function