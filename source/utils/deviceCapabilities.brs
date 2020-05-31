'Device Capabilities for Roku.
'This may need tweaking or be dynamically created if devices vary
'significantly

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
    if di.GetAudioOutputChannel() = "5.1 surround" then
      maxAudioChannels = 6
    end if

    return {
        "MaxStreamingBitrate": 120000000,
        "MaxStaticBitrate": 100000000,
        "MusicStreamingTranscodingBitrate": 192000,
        "DirectPlayProfiles": [
            {
                "Container": "mp4,m4v",
                "Type": "Video",
                "VideoCodec": "h264,vp8,vp9",
                "AudioCodec": "aac,opus,flac,vorbis"
            },
            {
                "Container": "mp3",
                "Type": "Audio",
                "AudioCodec": "mp3"
            },
            {
                "Container": "aac",
                "Type": "Audio"
            },
            {
                "Container": "m4a",
                "AudioCodec": "aac",
                "Type": "Audio"
            },
            {
                "Container": "flac",
                "Type": "Audio"
            }
        ],
        "TranscodingProfiles": [
            {
                "Container": "aac",
                "Type": "Audio",
                "AudioCodec": "aac",
                "Context": "Streaming",
                "Protocol": "http",
                "MaxAudioChannels": maxAudioChannels
            },
            {
                "Container": "mp3",
                "Type": "Audio",
                "AudioCodec": "mp3",
                "Context": "Streaming",
                "Protocol": "http",
                "MaxAudioChannels": 2
            },
            {
                "Container": "mp3",
                "Type": "Audio",
                "AudioCodec": "mp3",
                "Context": "Static",
                "Protocol": "http",
                "MaxAudioChannels": 2
            },
            {
                "Container": "aac",
                "Type": "Audio",
                "AudioCodec": "aac",
                "Context": "Static",
                "Protocol": "http",
                "MaxAudioChannels": maxAudioChannels
            },
            {
                "Container": "ts",
                "Type": "Video",
                "AudioCodec": "aac",
                "VideoCodec": "h264",
                "Context": "Streaming",
                "Protocol": "hls",
                "MaxAudioChannels": maxAudioChannels,
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
                "Format": "ass",
                "Method": "External"
            },
            {
                "Format": "ssa",
                "Method": "External"
            }
        ],
        "ResponseProfiles": [
            {
                "Type": "Video",
                "Container": "m4v",
                "MimeType": "video/mp4"
            }
        ]
    }
end function