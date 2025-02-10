Realtime
Beta
Communicate with a GPT-4o class model in real time using WebRTC or WebSockets. Supports text and audio inputs and ouputs, along with audio transcriptions. Learn more about the Realtime API.
Session tokens
REST API endpoint to generate ephemeral session tokens for use in client-side applications.
Create session
POST
 
https://api.openai.com/v1/realtime/sessions
Create an ephemeral API token for use in client-side applications with the Realtime API. Can be configured with the same session parameters as the session.update client event.

It responds with a session object, plus a client_secret key which contains a usable ephemeral API token that can be used to authenticate browser clients for the Realtime API.

Request body

modalities
Optional
The set of modalities the model can respond with. To disable audio, set this to ["text"].
model
string
Optional
The Realtime model used for this session.
instructions
string
Optional
The default system instructions (i.e. system message) prepended to model calls. This field allows the client to guide the model on desired responses. The model can be instructed on response content and format, (e.g. "be extremely succinct", "act friendly", "here are examples of good responses") and on audio behavior (e.g. "talk quickly", "inject emotion into your voice", "laugh frequently"). The instructions are not guaranteed to be followed by the model, but they provide guidance to the model on the desired behavior.

Note that the server sets default instructions which will be used if this field is not set and are visible in the session.created event at the start of the session.
voice
string
Optional
The voice the model uses to respond. Voice cannot be changed during the session once the model has responded with audio at least once. Current voice options are alloy, ash, ballad, coral, echo sage, shimmer and verse.
input_audio_format
string
Optional
The format of input audio. Options are pcm16, g711_ulaw, or g711_alaw. For pcm16, input audio must be 16-bit PCM at a 24kHz sample rate, single channel (mono), and little-endian byte order.
output_audio_format
string
Optional
The format of output audio. Options are pcm16, g711_ulaw, or g711_alaw. For pcm16, output audio is sampled at a rate of 24kHz.
input_audio_transcription
object
Optional
Configuration for input audio transcription, defaults to off and can be set to null to turn off once on. Input audio transcription is not native to the model, since the model consumes audio directly. Transcription runs asynchronously through OpenAI Whisper transcription and should be treated as rough guidance rather than the representation understood by the model. The client can optionally set the language and prompt for transcription, these fields will be passed to the Whisper API.

Show properties
turn_detection
object
Optional
Configuration for turn detection. Can be set to null to turn off. Server VAD means that the model will detect the start and end of speech based on audio volume and respond at the end of user speech.

Show properties
tools
array
Optional
Tools (functions) available to the model.

Show properties
tool_choice
string
Optional
How the model chooses tools. Options are auto, none, required, or specify a function.
temperature
number
Optional
Sampling temperature for the model, limited to [0.6, 1.2]. Defaults to 0.8.
max_response_output_tokens
integer or "inf"
Optional
Maximum number of output tokens for a single assistant response, inclusive of tool calls. Provide an integer between 1 and 4096 to limit output tokens, or inf for the maximum available tokens for a given model. Defaults to inf.
Returns

The created Realtime session object, plus an ephemeral key

Example request
curl -X POST https://api.openai.com/v1/realtime/sessions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o-realtime-preview-2024-12-17",
    "modalities": ["audio", "text"],
    "instructions": "You are a friendly assistant."
  }'
Response
{
  "id": "sess_001",
  "object": "realtime.session",
  "model": "gpt-4o-realtime-preview-2024-12-17",
  "modalities": ["audio", "text"],
  "instructions": "You are a friendly assistant.",
  "voice": "alloy",
  "input_audio_format": "pcm16",
  "output_audio_format": "pcm16",
  "input_audio_transcription": {
      "model": "whisper-1"
  },
  "turn_detection": null,
  "tools": [],
  "tool_choice": "none",
  "temperature": 0.7,
  "max_response_output_tokens": 200,
  "client_secret": {
    "value": "ek_abc123", 
    "expires_at": 1234567890
  }
}
The session object
A new Realtime session configuration, with an ephermeral key. Default TTL for keys is one minute.

client_secret
object
Ephemeral key returned by the API.

Show properties
modalities
The set of modalities the model can respond with. To disable audio, set this to ["text"].
instructions
string
The default system instructions (i.e. system message) prepended to model calls. This field allows the client to guide the model on desired responses. The model can be instructed on response content and format, (e.g. "be extremely succinct", "act friendly", "here are examples of good responses") and on audio behavior (e.g. "talk quickly", "inject emotion into your voice", "laugh frequently"). The instructions are not guaranteed to be followed by the model, but they provide guidance to the model on the desired behavior.

Note that the server sets default instructions which will be used if this field is not set and are visible in the session.created event at the start of the session.
voice
string
The voice the model uses to respond. Voice cannot be changed during the session once the model has responded with audio at least once. Current voice options are alloy, ash, ballad, coral, echo sage, shimmer and verse.
input_audio_format
string
The format of input audio. Options are pcm16, g711_ulaw, or g711_alaw.
output_audio_format
string
The format of output audio. Options are pcm16, g711_ulaw, or g711_alaw.
input_audio_transcription
object
Configuration for input audio transcription, defaults to off and can be set to null to turn off once on. Input audio transcription is not native to the model, since the model consumes audio directly. Transcription runs asynchronously through Whisper and should be treated as rough guidance rather than the representation understood by the model.

Show properties
turn_detection
object
Configuration for turn detection. Can be set to null to turn off. Server VAD means that the model will detect the start and end of speech based on audio volume and respond at the end of user speech.

Show properties
tools
array
Tools (functions) available to the model.

Show properties
tool_choice
string
How the model chooses tools. Options are auto, none, required, or specify a function.
temperature
number
Sampling temperature for the model, limited to [0.6, 1.2]. Defaults to 0.8.
max_response_output_tokens
integer or "inf"
Maximum number of output tokens for a single assistant response, inclusive of tool calls. Provide an integer between 1 and 4096 to limit output tokens, or inf for the maximum available tokens for a given model. Defaults to inf.
OBJECT The session object
{
  "id": "sess_001",
  "object": "realtime.session",
  "model": "gpt-4o-realtime-preview-2024-12-17",
  "modalities": ["audio", "text"],
  "instructions": "You are a friendly assistant.",
  "voice": "alloy",
  "input_audio_format": "pcm16",
  "output_audio_format": "pcm16",
  "input_audio_transcription": {
      "model": "whisper-1"
  },
  "turn_detection": null,
  "tools": [],
  "tool_choice": "none",
  "temperature": 0.7,
  "max_response_output_tokens": 200,
  "client_secret": {
    "value": "ek_abc123", 
    "expires_at": 1234567890
  }
}

Client events
These are events that the OpenAI Realtime WebSocket server will accept from the client.
session.update
Send this event to update the session’s default configuration. The client may send this event at any time to update the session configuration, and any field may be updated at any time, except for "voice". The server will respond with a session.updated event that shows the full effective configuration. Only fields that are present are updated, thus the correct way to clear a field like "instructions" is to pass an empty string.

event_id
string
Optional client-generated ID used to identify this event.
type
string
The event type, must be session.update.
session
object
Realtime session object configuration.

OBJECT session.update
{
    "event_id": "event_123",
    "type": "session.update",
    "session": {
        "modalities": ["text", "audio"],
        "instructions": "You are a helpful assistant.",
        "voice": "sage",
        "input_audio_format": "pcm16",
        "output_audio_format": "pcm16",
        "input_audio_transcription": {
            "model": "whisper-1"
        },
        "turn_detection": {
            "type": "server_vad",
            "threshold": 0.5,
            "prefix_padding_ms": 300,
            "silence_duration_ms": 500,
            "create_response": true
        },
        "tools": [
            {
                "type": "function",
                "name": "get_weather",
                "description": "Get the current weather...",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "location": { "type": "string" }
                    },
                    "required": ["location"]
                }
            }
        ],
        "tool_choice": "auto",
        "temperature": 0.8,
        "max_response_output_tokens": "inf"
    }
}

input_audio_buffer.append
Send this event to append audio bytes to the input audio buffer. The audio buffer is temporary storage you can write to and later commit. In Server VAD mode, the audio buffer is used to detect speech and the server will decide when to commit. When Server VAD is disabled, you must commit the audio buffer manually.

The client may choose how much audio to place in each event up to a maximum of 15 MiB, for example streaming smaller chunks from the client may allow the VAD to be more responsive. Unlike made other client events, the server will not send a confirmation response to this event.

event_id
string
Optional client-generated ID used to identify this event.
type
string
The event type, must be input_audio_buffer.append.
audio
string
Base64-encoded audio bytes. This must be in the format specified by the input_audio_format field in the session configuration.

OBJECT input_audio_buffer.append
{
    "event_id": "event_456",
    "type": "input_audio_buffer.append",
    "audio": "Base64EncodedAudioData"
}


input_audio_buffer.commit
Send this event to commit the user input audio buffer, which will create a new user message item in the conversation. This event will produce an error if the input audio buffer is empty. When in Server VAD mode, the client does not need to send this event, the server will commit the audio buffer automatically.

Committing the input audio buffer will trigger input audio transcription (if enabled in session configuration), but it will not create a response from the model. The server will respond with an input_audio_buffer.committed event.

event_id
string
Optional client-generated ID used to identify this event.
type
string
The event type, must be input_audio_buffer.commit.

OBJECT input_audio_buffer.commit
{
    "event_id": "event_789",
    "type": "input_audio_buffer.commit"
}

input_audio_buffer.clear
Send this event to clear the audio bytes in the buffer. The server will respond with an input_audio_buffer.cleared event.

event_id
string
Optional client-generated ID used to identify this event.
type
string
The event type, must be input_audio_buffer.clear.

BJECT input_audio_buffer.clear
{
    "event_id": "event_012",
    "type": "input_audio_buffer.clear"
}

onversation.item.create
Add a new Item to the Conversation's context, including messages, function calls, and function call responses. This event can be used both to populate a "history" of the conversation and to add new items mid-stream, but has the current limitation that it cannot populate assistant audio messages.

If successful, the server will respond with a conversation.item.created event, otherwise an error event will be sent.

event_id
string
Optional client-generated ID used to identify this event.
type
string
The event type, must be conversation.item.create.
previous_item_id
string
The ID of the preceding item after which the new item will be inserted. If not set, the new item will be appended to the end of the conversation. If set to root, the new item will be added to the beginning of the conversation. If set to an existing ID, it allows an item to be inserted mid-conversation. If the ID cannot be found, an error will be returned and the item will not be added.
item
object
The item to add to the conversation.

Show properties

OBJECT conversation.item.create
{
    "event_id": "event_345",
    "type": "conversation.item.create",
    "previous_item_id": null,
    "item": {
        "id": "msg_001",
        "type": "message",
        "role": "user",
        "content": [
            {
                "type": "input_text",
                "text": "Hello, how are you?"
            }
        ]
    }
}

conversation.item.truncate
Send this event to truncate a previous assistant message’s audio. The server will produce audio faster than realtime, so this event is useful when the user interrupts to truncate audio that has already been sent to the client but not yet played. This will synchronize the server's understanding of the audio with the client's playback.

Truncating audio will delete the server-side text transcript to ensure there is not text in the context that hasn't been heard by the user.

If successful, the server will respond with a conversation.item.truncated event.

event_id
string
Optional client-generated ID used to identify this event.
type
string
The event type, must be conversation.item.truncate.
item_id
string
The ID of the assistant message item to truncate. Only assistant message items can be truncated.
content_index
integer
The index of the content part to truncate. Set this to 0.
audio_end_ms
integer
Inclusive duration up to which audio is truncated, in milliseconds. If the audio_end_ms is greater than the actual audio duration, the server will respond with an error.

OBJECT conversation.item.truncate
{
    "event_id": "event_678",
    "type": "conversation.item.truncate",
    "item_id": "msg_002",
    "content_index": 0,
    "audio_end_ms": 1500
}

conversation.item.delete
Send this event when you want to remove any item from the conversation history. The server will respond with a conversation.item.deleted event, unless the item does not exist in the conversation history, in which case the server will respond with an error.

event_id
string
Optional client-generated ID used to identify this event.
type
string
The event type, must be conversation.item.delete.
item_id
string
The ID of the item to delete.

OBJECT conversation.item.delete
{
    "event_id": "event_901",
    "type": "conversation.item.delete",
    "item_id": "msg_003"
}

response.create
This event instructs the server to create a Response, which means triggering model inference. When in Server VAD mode, the server will create Responses automatically.

A Response will include at least one Item, and may have two, in which case the second will be a function call. These Items will be appended to the conversation history.

The server will respond with a response.created event, events for Items and content created, and finally a response.done event to indicate the Response is complete.

The response.create event includes inference configuration like instructions, and temperature. These fields will override the Session's configuration for this Response only.

event_id
string
Optional client-generated ID used to identify this event.
type
string
The event type, must be response.create.
response
object
Create a new Realtime response with these parameters

Show properties

OBJECT response.create
{
    "event_id": "event_234",
    "type": "response.create",
    "response": {
        "modalities": ["text", "audio"],
        "instructions": "Please assist the user.",
        "voice": "sage",
        "output_audio_format": "pcm16",
        "tools": [
            {
                "type": "function",
                "name": "calculate_sum",
                "description": "Calculates the sum of two numbers.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "a": { "type": "number" },
                        "b": { "type": "number" }
                    },
                    "required": ["a", "b"]
                }
            }
        ],
        "tool_choice": "auto",
        "temperature": 0.8,
        "max_output_tokens": 1024
    }
}

response.cancel
Send this event to cancel an in-progress response. The server will respond with a response.cancelled event or an error if there is no response to cancel.

event_id
string
Optional client-generated ID used to identify this event.
type
string
The event type, must be response.cancel.
response_id
string
A specific response ID to cancel - if not provided, will cancel an in-progress response in the default conversation.

OBJECT response.cancel
{
    "event_id": "event_567",
    "type": "response.cancel"
}

Server events
These are events emitted from the OpenAI Realtime WebSocket server to the client.
error
Returned when an error occurs, which could be a client problem or a server problem. Most errors are recoverable and the session will stay open, we recommend to implementors to monitor and log error messages by default.

event_id
string
The unique ID of the server event.
type
string
The event type, must be error.
error
object
Details of the error.

Show properties

OBJECT error
{
    "event_id": "event_890",
    "type": "error",
    "error": {
        "type": "invalid_request_error",
        "code": "invalid_event",
        "message": "The 'type' field is missing.",
        "param": null,
        "event_id": "event_567"
    }
}

session.created
Returned when a Session is created. Emitted automatically when a new connection is established as the first server event. This event will contain the default Session configuration.

event_id
string
The unique ID of the server event.
type
string
The event type, must be session.created.
session
object
Realtime session object configuration.

Show properties

OBJECT session.created
{
    "event_id": "event_1234",
    "type": "session.created",
    "session": {
        "id": "sess_001",
        "object": "realtime.session",
        "model": "gpt-4o-realtime-preview-2024-12-17",
        "modalities": ["text", "audio"],
        "instructions": "...model instructions here...",
        "voice": "sage",
        "input_audio_format": "pcm16",
        "output_audio_format": "pcm16",
        "input_audio_transcription": null,
        "turn_detection": {
            "type": "server_vad",
            "threshold": 0.5,
            "prefix_padding_ms": 300,
            "silence_duration_ms": 200
        },
        "tools": [],
        "tool_choice": "auto",
        "temperature": 0.8,
        "max_response_output_tokens": "inf"
    }
}

session.updated
Returned when a session is updated with a session.update event, unless there is an error.

event_id
string
The unique ID of the server event.
type
string
The event type, must be session.updated.
session
object
Realtime session object configuration.

Show properties
OBJECT session.updated
{
    "event_id": "event_5678",
    "type": "session.updated",
    "session": {
        "id": "sess_001",
        "object": "realtime.session",
        "model": "gpt-4o-realtime-preview-2024-12-17",
        "modalities": ["text"],
        "instructions": "New instructions",
        "voice": "sage",
        "input_audio_format": "pcm16",
        "output_audio_format": "pcm16",
        "input_audio_transcription": {
            "model": "whisper-1"
        },
        "turn_detection": null,
        "tools": [],
        "tool_choice": "none",
        "temperature": 0.7,
        "max_response_output_tokens": 200
    }
}

conversation.created
Returned when a conversation is created. Emitted right after session creation.

event_id
string
The unique ID of the server event.
type
string
The event type, must be conversation.created.
conversation
object
The conversation resource.

Show properties
OBJECT conversation.created
{
    "event_id": "event_9101",
    "type": "conversation.created",
    "conversation": {
        "id": "conv_001",
        "object": "realtime.conversation"
    }
}

conversation.item.created
Returned when a conversation item is created. There are several scenarios that produce this event:

The server is generating a Response, which if successful will produce either one or two Items, which will be of type message (role assistant) or type function_call.
The input audio buffer has been committed, either by the client or the server (in server_vad mode). The server will take the content of the input audio buffer and add it to a new user message Item.
The client has sent a conversation.item.create event to add a new Item to the Conversation.
event_id
string
The unique ID of the server event.
type
string
The event type, must be conversation.item.created.
previous_item_id
string
The ID of the preceding item in the Conversation context, allows the client to understand the order of the conversation.
item
object
The item to add to the conversation.

Show properties
OBJECT conversation.item.created
{
    "event_id": "event_1920",
    "type": "conversation.item.created",
    "previous_item_id": "msg_002",
    "item": {
        "id": "msg_003",
        "object": "realtime.item",
        "type": "message",
        "status": "completed",
        "role": "user",
        "content": [
            {
                "type": "input_audio",
                "transcript": "hello how are you",
                "audio": "base64encodedaudio=="
            }
        ]
    }
}

conversation.item.input_audio_transcription.completed
This event is the output of audio transcription for user audio written to the user audio buffer. Transcription begins when the input audio buffer is committed by the client or server (in server_vad mode). Transcription runs asynchronously with Response creation, so this event may come before or after the Response events.

Realtime API models accept audio natively, and thus input transcription is a separate process run on a separate ASR (Automatic Speech Recognition) model, currently always whisper-1. Thus the transcript may diverge somewhat from the model's interpretation, and should be treated as a rough guide.

event_id
string
The unique ID of the server event.
type
string
The event type, must be conversation.item.input_audio_transcription.completed.
item_id
string
The ID of the user message item containing the audio.
content_index
integer
The index of the content part containing the audio.
transcript
string
The transcribed text.
OBJECT conversation.item.input_audio_transcription.completed
{
    "event_id": "event_2122",
    "type": "conversation.item.input_audio_transcription.completed",
    "item_id": "msg_003",
    "content_index": 0,
    "transcript": "Hello, how are you?"
}


conversation.item.input_audio_transcription.failed
Returned when input audio transcription is configured, and a transcription request for a user message failed. These events are separate from other error events so that the client can identify the related Item.

event_id
string
The unique ID of the server event.
type
string
The event type, must be conversation.item.input_audio_transcription.failed.
item_id
string
The ID of the user message item.
content_index
integer
The index of the content part containing the audio.
error
object
Details of the transcription error.

Show properties
OBJECT conversation.item.input_audio_transcription.failed
{
    "event_id": "event_2324",
    "type": "conversation.item.input_audio_transcription.failed",
    "item_id": "msg_003",
    "content_index": 0,
    "error": {
        "type": "transcription_error",
        "code": "audio_unintelligible",
        "message": "The audio could not be transcribed.",
        "param": null
    }
}

conversation.item.truncated
Returned when an earlier assistant audio message item is truncated by the client with a conversation.item.truncate event. This event is used to synchronize the server's understanding of the audio with the client's playback.

This action will truncate the audio and remove the server-side text transcript to ensure there is no text in the context that hasn't been heard by the user.

event_id
string
The unique ID of the server event.
type
string
The event type, must be conversation.item.truncated.
item_id
string
The ID of the assistant message item that was truncated.
content_index
integer
The index of the content part that was truncated.
audio_end_ms
integer
The duration up to which the audio was truncated, in milliseconds.
OBJECT conversation.item.truncated
{
    "event_id": "event_2526",
    "type": "conversation.item.truncated",
    "item_id": "msg_004",
    "content_index": 0,
    "audio_end_ms": 1500
}

conversation.item.deleted
Returned when an item in the conversation is deleted by the client with a conversation.item.delete event. This event is used to synchronize the server's understanding of the conversation history with the client's view.

event_id
string
The unique ID of the server event.
type
string
The event type, must be conversation.item.deleted.
item_id
string
The ID of the item that was deleted.
OBJECT conversation.item.deleted
{
    "event_id": "event_2728",
    "type": "conversation.item.deleted",
    "item_id": "msg_005"
}
input_audio_buffer.committed
Returned when an input audio buffer is committed, either by the client or automatically in server VAD mode. The item_id property is the ID of the user message item that will be created, thus a conversation.item.created event will also be sent to the client.

event_id
string
The unique ID of the server event.
type
string
The event type, must be input_audio_buffer.committed.
previous_item_id
string
The ID of the preceding item after which the new item will be inserted.
item_id
string
The ID of the user message item that will be created.
OBJECT input_audio_buffer.committed
{
    "event_id": "event_1121",
    "type": "input_audio_buffer.committed",
    "previous_item_id": "msg_001",
    "item_id": "msg_002"
}

input_audio_buffer.cleared
Returned when the input audio buffer is cleared by the client with a input_audio_buffer.clear event.

event_id
string
The unique ID of the server event.
type
string
The event type, must be input_audio_buffer.cleared.
OBJECT input_audio_buffer.cleared
{
    "event_id": "event_1314",
    "type": "input_audio_buffer.cleared"
}

input_audio_buffer.speech_started
Sent by the server when in server_vad mode to indicate that speech has been detected in the audio buffer. This can happen any time audio is added to the buffer (unless speech is already detected). The client may want to use this event to interrupt audio playback or provide visual feedback to the user.

The client should expect to receive a input_audio_buffer.speech_stopped event when speech stops. The item_id property is the ID of the user message item that will be created when speech stops and will also be included in the input_audio_buffer.speech_stopped event (unless the client manually commits the audio buffer during VAD activation).

event_id
string
The unique ID of the server event.
type
string
The event type, must be input_audio_buffer.speech_started.
audio_start_ms
integer
Milliseconds from the start of all audio written to the buffer during the session when speech was first detected. This will correspond to the beginning of audio sent to the model, and thus includes the prefix_padding_ms configured in the Session.
item_id
string
The ID of the user message item that will be created when speech stops.
OBJECT input_audio_buffer.speech_started
{
    "event_id": "event_1516",
    "type": "input_audio_buffer.speech_started",
    "audio_start_ms": 1000,
    "item_id": "msg_003"
}

input_audio_buffer.speech_stopped
Returned in server_vad mode when the server detects the end of speech in the audio buffer. The server will also send an conversation.item.created event with the user message item that is created from the audio buffer.

event_id
string
The unique ID of the server event.
type
string
The event type, must be input_audio_buffer.speech_stopped.
audio_end_ms
integer
Milliseconds since the session started when speech stopped. This will correspond to the end of audio sent to the model, and thus includes the min_silence_duration_ms configured in the Session.
item_id
string
The ID of the user message item that will be created.
OBJECT input_audio_buffer.speech_stopped
{
    "event_id": "event_1718",
    "type": "input_audio_buffer.speech_stopped",
    "audio_end_ms": 2000,
    "item_id": "msg_003"
}

response.created
Returned when a new Response is created. The first event of response creation, where the response is in an initial state of in_progress.

event_id
string
The unique ID of the server event.
type
string
The event type, must be response.created.
response
object
The response resource.

Show properties
OBJECT response.created
{
    "event_id": "event_2930",
    "type": "response.created",
    "response": {
        "id": "resp_001",
        "object": "realtime.response",
        "status": "in_progress",
        "status_details": null,
        "output": [],
        "usage": null
    }
}

response.done
Returned when a Response is done streaming. Always emitted, no matter the final state. The Response object included in the response.done event will include all output Items in the Response but will omit the raw audio data.

event_id
string
The unique ID of the server event.
type
string
The event type, must be response.done.
response
object
The response resource.

Show properties
OBJECT response.done
{
    "event_id": "event_3132",
    "type": "response.done",
    "response": {
        "id": "resp_001",
        "object": "realtime.response",
        "status": "completed",
        "status_details": null,
        "output": [
            {
                "id": "msg_006",
                "object": "realtime.item",
                "type": "message",
                "status": "completed",
                "role": "assistant",
                "content": [
                    {
                        "type": "text",
                        "text": "Sure, how can I assist you today?"
                    }
                ]
            }
        ],
        "usage": {
            "total_tokens":275,
            "input_tokens":127,
            "output_tokens":148,
            "input_token_details": {
                "cached_tokens":384,
                "text_tokens":119,
                "audio_tokens":8,
                "cached_tokens_details": {
                    "text_tokens": 128,
                    "audio_tokens": 256
                }
            },
            "output_token_details": {
              "text_tokens":36,
              "audio_tokens":112
            }
        }
    }
}

response.output_item.added
Returned when a new Item is created during Response generation.

event_id
string
The unique ID of the server event.
type
string
The event type, must be response.output_item.added.
response_id
string
The ID of the Response to which the item belongs.
output_index
integer
The index of the output item in the Response.
item
object
The item to add to the conversation.

Show properties
OBJECT response.output_item.added
{
    "event_id": "event_3334",
    "type": "response.output_item.added",
    "response_id": "resp_001",
    "output_index": 0,
    "item": {
        "id": "msg_007",
        "object": "realtime.item",
        "type": "message",
        "status": "in_progress",
        "role": "assistant",
        "content": []
    }
}

response.output_item.done
Returned when an Item is done streaming. Also emitted when a Response is interrupted, incomplete, or cancelled.

event_id
string
The unique ID of the server event.
type
string
The event type, must be response.output_item.done.
response_id
string
The ID of the Response to which the item belongs.
output_index
integer
The index of the output item in the Response.
item
object
The item to add to the conversation.

Show properties
OBJECT response.output_item.done
{
    "event_id": "event_3536",
    "type": "response.output_item.done",
    "response_id": "resp_001",
    "output_index": 0,
    "item": {
        "id": "msg_007",
        "object": "realtime.item",
        "type": "message",
        "status": "completed",
        "role": "assistant",
        "content": [
            {
                "type": "text",
                "text": "Sure, I can help with that."
            }
        ]
    }
}

response.content_part.added
Returned when a new content part is added to an assistant message item during response generation.

event_id
string
The unique ID of the server event.
type
string
The event type, must be response.content_part.added.
response_id
string
The ID of the response.
item_id
string
The ID of the item to which the content part was added.
output_index
integer
The index of the output item in the response.
content_index
integer
The index of the content part in the item's content array.
part
object
The content part that was added.

Show properties
OBJECT response.content_part.added
{
    "event_id": "event_3738",
    "type": "response.content_part.added",
    "response_id": "resp_001",
    "item_id": "msg_007",
    "output_index": 0,
    "content_index": 0,
    "part": {
        "type": "text",
        "text": ""
    }
}

response.content_part.done
Returned when a content part is done streaming in an assistant message item. Also emitted when a Response is interrupted, incomplete, or cancelled.

event_id
string
The unique ID of the server event.
type
string
The event type, must be response.content_part.done.
response_id
string
The ID of the response.
item_id
string
The ID of the item.
output_index
integer
The index of the output item in the response.
content_index
integer
The index of the content part in the item's content array.
part
object
The content part that is done.

Show properties
OBJECT response.content_part.done
{
    "event_id": "event_3940",
    "type": "response.content_part.done",
    "response_id": "resp_001",
    "item_id": "msg_007",
    "output_index": 0,
    "content_index": 0,
    "part": {
        "type": "text",
        "text": "Sure, I can help with that."
    }
}


response.text.delta
Returned when the text value of a "text" content part is updated.

event_id
string
The unique ID of the server event.
type
string
The event type, must be response.text.delta.
response_id
string
The ID of the response.
item_id
string
The ID of the item.
output_index
integer
The index of the output item in the response.
content_index
integer
The index of the content part in the item's content array.
delta
string
The text delta.
OBJECT response.text.delta
{
    "event_id": "event_4142",
    "type": "response.text.delta",
    "response_id": "resp_001",
    "item_id": "msg_007",
    "output_index": 0,
    "content_index": 0,
    "delta": "Sure, I can h"
}


response.text.done
Returned when the text value of a "text" content part is done streaming. Also emitted when a Response is interrupted, incomplete, or cancelled.

event_id
string
The unique ID of the server event.
type
string
The event type, must be response.text.done.
response_id
string
The ID of the response.
item_id
string
The ID of the item.
output_index
integer
The index of the output item in the response.
content_index
integer
The index of the content part in the item's content array.
text
string
The final text content.
OBJECT response.text.done
{
    "event_id": "event_4344",
    "type": "response.text.done",
    "response_id": "resp_001",
    "item_id": "msg_007",
    "output_index": 0,
    "content_index": 0,
    "text": "Sure, I can help with that."
}


response.audio_transcript.delta
Returned when the model-generated transcription of audio output is updated.

event_id
string
The unique ID of the server event.
type
string
The event type, must be response.audio_transcript.delta.
response_id
string
The ID of the response.
item_id
string
The ID of the item.
output_index
integer
The index of the output item in the response.
content_index
integer
The index of the content part in the item's content array.
delta
string
The transcript delta.
OBJECT response.audio_transcript.delta
{
    "event_id": "event_4546",
    "type": "response.audio_transcript.delta",
    "response_id": "resp_001",
    "item_id": "msg_008",
    "output_index": 0,
    "content_index": 0,
    "delta": "Hello, how can I a"
}


response.audio_transcript.done
Returned when the model-generated transcription of audio output is done streaming. Also emitted when a Response is interrupted, incomplete, or cancelled.

event_id
string
The unique ID of the server event.
type
string
The event type, must be response.audio_transcript.done.
response_id
string
The ID of the response.
item_id
string
The ID of the item.
output_index
integer
The index of the output item in the response.
content_index
integer
The index of the content part in the item's content array.
transcript
string
The final transcript of the audio.
OBJECT response.audio_transcript.done
{
    "event_id": "event_4748",
    "type": "response.audio_transcript.done",
    "response_id": "resp_001",
    "item_id": "msg_008",
    "output_index": 0,
    "content_index": 0,
    "transcript": "Hello, how can I assist you today?"
}

response.audio.delta
Returned when the model-generated audio is updated.

event_id
string
The unique ID of the server event.
type
string
The event type, must be response.audio.delta.
response_id
string
The ID of the response.
item_id
string
The ID of the item.
output_index
integer
The index of the output item in the response.
content_index
integer
The index of the content part in the item's content array.
delta
string
Base64-encoded audio data delta.
OBJECT response.audio.delta
{
    "event_id": "event_4950",
    "type": "response.audio.delta",
    "response_id": "resp_001",
    "item_id": "msg_008",
    "output_index": 0,
    "content_index": 0,
    "delta": "Base64EncodedAudioDelta"
}


response.audio.done
Returned when the model-generated audio is done. Also emitted when a Response is interrupted, incomplete, or cancelled.

event_id
string
The unique ID of the server event.
type
string
The event type, must be response.audio.done.
response_id
string
The ID of the response.
item_id
string
The ID of the item.
output_index
integer
The index of the output item in the response.
content_index
integer
The index of the content part in the item's content array.
OBJECT response.audio.done
{
    "event_id": "event_5152",
    "type": "response.audio.done",
    "response_id": "resp_001",
    "item_id": "msg_008",
    "output_index": 0,
    "content_index": 0
}


response.function_call_arguments.delta
Returned when the model-generated function call arguments are updated.

event_id
string
The unique ID of the server event.
type
string
The event type, must be response.function_call_arguments.delta.
response_id
string
The ID of the response.
item_id
string
The ID of the function call item.
output_index
integer
The index of the output item in the response.
call_id
string
The ID of the function call.
delta
string
The arguments delta as a JSON string.
OBJECT response.function_call_arguments.delta
{
    "event_id": "event_5354",
    "type": "response.function_call_arguments.delta",
    "response_id": "resp_002",
    "item_id": "fc_001",
    "output_index": 0,
    "call_id": "call_001",
    "delta": "{\"location\": \"San\""
}

response.function_call_arguments.done
Returned when the model-generated function call arguments are done streaming. Also emitted when a Response is interrupted, incomplete, or cancelled.

event_id
string
The unique ID of the server event.
type
string
The event type, must be response.function_call_arguments.done.
response_id
string
The ID of the response.
item_id
string
The ID of the function call item.
output_index
integer
The index of the output item in the response.
call_id
string
The ID of the function call.
arguments
string
The final arguments as a JSON string.
OBJECT response.function_call_arguments.done
{
    "event_id": "event_5556",
    "type": "response.function_call_arguments.done",
    "response_id": "resp_002",
    "item_id": "fc_001",
    "output_index": 0,
    "call_id": "call_001",
    "arguments": "{\"location\": \"San Francisco\"}"
}

rate_limits.updated
Emitted at the beginning of a Response to indicate the updated rate limits. When a Response is created some tokens will be "reserved" for the output tokens, the rate limits shown here reflect that reservation, which is then adjusted accordingly once the Response is completed.

event_id
string
The unique ID of the server event.
type
string
The event type, must be rate_limits.updated.
rate_limits
array
List of rate limit information.

Show properties
OBJECT rate_limits.updated
{
    "event_id": "event_5758",
    "type": "rate_limits.updated",
    "rate_limits": [
        {
            "name": "requests",
            "limit": 1000,
            "remaining": 999,
            "reset_seconds": 60
        },
        {
            "name": "tokens",
            "limit": 50000,
            "remaining": 49950,
            "reset_seconds": 60
        }
    ]
}

Realtime API

Beta

====================

Build low-latency, multi-modal experiences with the Realtime API.

The OpenAI Realtime API enables you to build low-latency, multi-modal conversational experiences with [expressive voice-enabled models](/docs/models#gpt-4o-realtime). These models support realtime text and audio inputs and outputs, voice activation detection, function calling, and much more.

The Realtime API uses GPT-4o and GPT-4o-mini models with additional capabilities to support realtime interactions. The most recent model snapshots for each can be referenced by:

*   `gpt-4o-realtime-preview-2024-12-17`
*   `gpt-4o-mini-realtime-preview-2024-12-17`

Dated model snapshot IDs and more information can be found on the [models page here](/docs/models#gpt-4o-realtime).

Get started with the Realtime API
---------------------------------

Learn to connect to the Realtime API using either WebRTC (ideal for client-side applications) or WebSockets (great for server-to-server applications). Once you connect to the Realtime API, learn how to use client and server events to build your application.

[

Connect to the Realtime API using WebRTC

To interact with Realtime models in web browsers or client-side applications, we recommend connecting via WebRTC. Learn how in this guide!

](/docs/guides/realtime-webrtc)[

Connect to the Realtime API using WebSockets

In server-to-server applications, you can connect to the Realtime API over WebSocket as well. Learn how in this guide!

](/docs/guides/realtime-websocket)[

Realtime model capabilities

Learn to use the Realtime API's evented interface to build applications using Realtime models. Learn to manage the Realtime session, add audio to model conversations, send text generation requests to the model, and make function calls to extend the capabilities of the model.

](/docs/guides/realtime-model-capabilities)[

Python SDK

Beta support in the Python SDK for connecting to the Realtime API over a WebSocket.

](https://github.com/openai/openai-python)[

Full API reference

Check out the API reference for all available interfaces.

](/docs/api-reference/realtime)

Example applications
--------------------

Check out one of the example applications below to see the Realtime API in action.

[

Realtime Console

To get started quickly, download and configure the Realtime console demo. See events flowing back and forth, and inspect their contents. Learn how to execute custom logic with function calling.

](https://github.com/openai/openai-realtime-console)[](https://github.com/craigsdennis/talk-to-javascript-openai-workers)

[

](https://github.com/craigsdennis/talk-to-javascript-openai-workers)

[

Client-side tool calling

](https://github.com/craigsdennis/talk-to-javascript-openai-workers)

[](https://github.com/craigsdennis/talk-to-javascript-openai-workers)

[Built with Cloudflare Workers, an example application showcasing client-side tool calling. Also check out the](https://github.com/craigsdennis/talk-to-javascript-openai-workers) [tutorial on YouTube](https://www.youtube.com/watch?v=TcOytsfva0o).

Partner integrations
--------------------

Check out these partner integrations, which use the Realtime API in frontend applications and telephony use cases.

[

LiveKit integration guide

How to use the Realtime API with LiveKit's WebRTC infrastructure.

](https://docs.livekit.io/agents/openai/overview/)[

Twilio integration guide

Build Realtime apps using Twilio's powerful voice APIs.

](https://www.twilio.com/en-us/blog/twilio-openai-realtime-api-launch-integration)[

Agora integration quickstart

How to integrate Agora's real-time audio communication capabilities with the Realtime API.

](https://docs.agora.io/en/open-ai-integration/get-started/quickstart)

Was this page useful?

Realtime API with WebSockets

Beta

====================================

Use WebSockets to connect to the Realtime API in server-to-server applications.

[WebSockets](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API) are a broadly supported API for realtime data transfer, and a great choice for connecting to the OpenAI Realtime API in server-to-server applications. For browser and mobile clients, we recommend connecting via [WebRTC](/docs/guides/realtime-webrtc). Follow this guide to connect to the Realtime API via WebSocket and start interacting with a Realtime model.

Overview
--------

In a server-to-server integration with Realtime, your backend system will connect via WebSocket directly to the Realtime API. You can use a [standard API key](/settings/organization/api-keys) to authenticate this connection, since the token will only be available on your secure backend server.

![connect directly to realtime API](https://openaidevs.retool.com/api/file/464d4334-c467-4862-901b-d0c6847f003a)

WebSocket connections can also be authenticated with an ephemeral client token ([as shown here in the WebRTC connection guide](/docs/guides/realtime-webrtc)) if you choose to connect to the Realtime API via WebSocket on a client device.

  

Standard OpenAI API tokens **should only be used in secure server-side environments**.

Connection details
------------------

Connecting via WebSocket requires the following connection information:

|URL|wss://api.openai.com/v1/realtime|
|Query Parameters|modelRealtime model ID to connect to, like gpt-4o-realtime-preview-2024-12-17|
|Headers|Authorization: Bearer YOUR_API_KEYSubstitute YOUR_API_KEY with a standard API key on the server, or an ephemeral token on insecure clients (note that WebRTC is recommended for this use case).OpenAI-Beta: realtime=v1This header is required during the beta period.|

Below are several examples of using these connection details to initialize a WebSocket connection to the Realtime API.

ws module (Node.js)

Connect using the ws module (Node.js)

```javascript
import WebSocket from "ws";

const url = "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-12-17";
const ws = new WebSocket(url, {
  headers: {
    "Authorization": "Bearer " + process.env.OPENAI_API_KEY,
    "OpenAI-Beta": "realtime=v1",
  },
});

ws.on("open", function open() {
  console.log("Connected to server.");
});

ws.on("message", function incoming(message) {
  console.log(JSON.parse(message.toString()));
});
```

websocket-client (Python)

Connect with websocket-client (Python)

```python
# example requires websocket-client library:
# pip install websocket-client

import os
import json
import websocket

OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")

url = "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-12-17"
headers = [
    "Authorization: Bearer " + OPENAI_API_KEY,
    "OpenAI-Beta: realtime=v1"
]

def on_open(ws):
    print("Connected to server.")

def on_message(ws, message):
    data = json.loads(message)
    print("Received event:", json.dumps(data, indent=2))

ws = websocket.WebSocketApp(
    url,
    header=headers,
    on_open=on_open,
    on_message=on_message,
)

ws.run_forever()
```

WebSocket (browsers)

Connect with standard WebSocket (browsers)

```javascript
/*
Note that in client-side environments like web browsers, we recommend
using WebRTC instead. It is possible, however, to use the standard 
WebSocket interface in browser-like environments like Deno and 
Cloudflare Workers.
*/

const ws = new WebSocket(
  "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-12-17",
  [
    "realtime",
    // Auth
    "openai-insecure-api-key." + OPENAI_API_KEY, 
    // Optional
    "openai-organization." + OPENAI_ORG_ID,
    "openai-project." + OPENAI_PROJECT_ID,
    // Beta protocol, required
    "openai-beta.realtime-v1"
  ]
);

ws.on("open", function open() {
  console.log("Connected to server.");
});

ws.on("message", function incoming(message) {
  console.log(message.data);
});
```

Sending and receiving events
----------------------------

To interact with the Realtime models, you will send and receive messages over the WebSocket interface. The full list of messages that clients can send, and that will be sent from the server, are found in the [API reference](/docs/api-reference/realtime-client-events). Once connected, you'll send and receive events which represent text, audio, function calls, interruptions, configuration updates, and more.

Below, you'll find examples of how to send and receive events over the WebSocket interface in several programming environments.

WebSocket (Node.js / browser)

Send and receive events on a WebSocket (Node.js / browser)

```javascript
// Server-sent events will come in as messages...
ws.on("message", function incoming(message) {
  // Message data payloads will need to be parsed from JSON:
  const serverEvent = JSON.parse(message.data)
  console.log(serverEvent);
});

// To send events, create a JSON-serializeable data structure that
// matches a client-side event (see API reference)
const event = {
  type: "response.create",
  response: {
    modalities: ["audio", "text"],
    instructions: "Give me a haiku about code.",
  }
};
ws.send(JSON.stringify(event));
```

websocket-client (Python)

Send and receive messages with websocket-client (Python)

```python
# To send a client event, serialize a dictionary to JSON
# of the proper event type
def on_open(ws):
    print("Connected to server.")
    
    event = {
        "type": "response.create",
        "response": {
            "modalities": ["text"],
            "instructions": "Please assist the user."
        }
    }
    ws.send(json.dumps(event))

# Receiving messages will require parsing message payloads
# from JSON
def on_message(ws, message):
    data = json.loads(message)
    print("Received event:", json.dumps(data, indent=2))
```

Next steps
----------

Now that you have a functioning WebSocket connection to the Realtime API, it's time to learn more about building applications with Realtime models.

[

Realtime model capabilities

Learn about sessions with a Realtime model, where you can send and receive audio, manage conversations, make one-off requests to the model, and execute function calls.

](/docs/guides/realtime-model-capabilities)[

Event API reference

A complete listing of client and server events in the Realtime API

](/docs/api-reference/realtime-client-events)

Was this page useful?

Realtime model capabilities

Beta

===================================

Learn how to manage Realtime sessions, conversations, model responses, and function calls.

Once you have connected to the Realtime API through either [WebRTC](/docs/guides/realtime-webrtc) or [WebSocket](/docs/guides/realtime-websocket), you can build applications with a Realtime AI model. Doing so will require you to **send client events** to initiate actions, and **listen for server events** to respond to actions taken by the Realtime API. This guide will walk through the event flows required to use model capabilities like audio and text generation, and how to think about the state of a Realtime session.

About Realtime sessions
-----------------------

A Realtime session is a stateful interaction between the model and a connected client. The key components of the session are:

*   The **session** object, which controls the parameters of the interaction, like the model being used, the voice used to generate output, and other configuration.
*   A **conversation**, which represents user inputs and model outputs generated during the current session.
*   **Responses**, which are model-generated audio or text outputs that are added to the conversation.

**Input audio buffer and WebSockets**

If you are using WebRTC, much of the media handling required to send and receive audio from the model is assisted by WebRTC browser APIs.

  

If you are using WebSockets for audio, you will need to manually interact with the **input audio buffer** as well as the objects listed above. You'll be responsible for sending and receiving Base64-encoded audio bytes, and handling those as appropriate in your integration code.

All these components together make up a Realtime session. You will use client-sent events to update the state of the session, and listen for server-sent events to react to state changes within the session.

![diagram realtime state](https://openaidevs.retool.com/api/file/11fe71d2-611e-4a26-a587-881719a90e56)

Session lifecycle events
------------------------

After initiating a session via either [WebRTC](/docs/guides/realtime-webrtc) or [WebSockets](/docs/guides/realtime-websockets), the server will send a [`session.created`](/docs/api-reference/realtime-server-events/session/created) event indicating the session is ready. On the client, you can update the current session configuration with the [`session.update`](/docs/api-reference/realtime-client-events/session/update) event. Most session properties can be updated at any time, except for the `voice` the model uses for audio output, after the model has responded with audio once during the session. The maximum duration of a Realtime session is **30 minutes**.

The following example shows updating the session with a `session.update` client event. See the [WebRTC](/docs/guides/realtime-webrtc#sending-and-receiving-events) or [WebSocket](/docs/guides/realtime-websocket#sending-and-receiving-events) guide for more on sending client events over these channels.

Update the system instructions used by the model in this session

```javascript
const event = {
  type: "session.update",
  session: {
    instructions: "Never use the word 'moist' in your responses!"
  },
};

// WebRTC data channel and WebSocket both have .send()
dataChannel.send(JSON.stringify(event));
```

```python
event = {
    "type": "session.update",
    "session": {
        "instructions": "Never use the word 'moist' in your responses!"
    }
}
ws.send(json.dumps(event))
```

When the session has been updated, the server will emit a [`session.updated`](/docs/api-reference/realtime-server-events/session/updated) event with the new state of the session.

||
|session.update|session.createdsession.updated|

Text inputs and outputs
-----------------------

To generate text with a Realtime model, you can add text inputs to the current conversation, ask the model to generate a response, and listen for server-sent events indicating the progress of the model's response. In order to generate text, the [session must be configured](/docs/api-reference/realtime-client-events/session/update) with the `text` modality (this is true by default).

Create a new text conversation item using the [`conversation.item.create`](/docs/api-reference/realtime-client-events/conversation/item/create) client event. This is similar to sending a [user message (prompt) in chat completions](/docs/guides/text-generation) in the REST API.

Create a conversation item with user input

```javascript
const event = {
  type: "conversation.item.create",
  item: {
    type: "message",
    role: "user",
    content: [
      {
        type: "input_text",
        text: "What Prince album sold the most copies?",
      }
    ]
  },
};

// WebRTC data channel and WebSocket both have .send()
dataChannel.send(JSON.stringify(event));
```

```python
event = {
    "type": "conversation.item.create",
    "item": {
        "type": "message",
        "role": "user",
        "content": [
            {
                "type": "input_text",
                "text": "What Prince album sold the most copies?",
            }
        ]
    }
}
ws.send(json.dumps(event))
```

After adding the user message to the conversation, send the [`response.create`](/docs/api-reference/realtime-client-events/response/create) event to initiate a response from the model. If both audio and text are enabled for the current session, the model will respond with both audio and text content. If you'd like to generate text only, you can specify that when sending the `response.create` client event, as shown below.

Generate a text-only response

```javascript
const event = {
  type: "response.create",
  response: {
    modalities: [ "text" ]
  },
};

// WebRTC data channel and WebSocket both have .send()
dataChannel.send(JSON.stringify(event));
```

```python
event = {
    "type": "response.create",
    "response": {
        "modalities": [ "text" ]
    }
}
ws.send(json.dumps(event))
```

When the response is completely finished, the server will emit the [`response.done`](/docs/api-reference/realtime-server-events/response/done) event. This event will contain the full text generated by the model, as shown below.

Listen for response.done to see the final results

```javascript
function handleEvent(e) {
  const serverEvent = JSON.parse(e.data);
  if (serverEvent.type === "response.done") {
    console.log(serverEvent.response.output[0]);
  }
}

// Listen for server messages (WebRTC)
dataChannel.addEventListener("message", handleEvent);

// Listen for server messages (WebSocket)
// ws.on("message", handleEvent);
```

```python
def on_message(ws, message):
    server_event = json.loads(message)
    if server_event.type == "response.done":
        print(server_event.response.output[0])
```

While the model response is being generated, the server will emit a number of lifecycle events during the process. You can listen for these events, such as [`response.text.delta`](/docs/api-reference/realtime-server-events/response/text/delta), to provide realtime feedback to users as the response is generated. A full listing of the events emitted by there server are found below under **related server events**. They are provided in the rough order of when they are emitted, along with relevant client-side events for text generation.

||
|conversation.item.createresponse.create|conversation.item.createdresponse.createdresponse.output_item.addedresponse.content_part.addedresponse.text.deltaresponse.text.doneresponse.content_part.doneresponse.output_item.doneresponse.donerate_limits.updated|

Audio inputs and outputs
------------------------

One of the most powerful features of the Realtime API is voice-to-voice interaction with the model, without an intermediate text-to-speech or speech-to-text step. This enables lower latency for voice interfaces, and gives the model more data to work with around the tone and inflection of voice input.

### Handling audio with WebRTC

If you are connecting to the Realtime API using WebRTC, the Realtime API is acting as a [peer connection](https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection) to your client. Audio output from the model is delivered to your client as a [remote media stream](hhttps://developer.mozilla.org/en-US/docs/Web/API/MediaStream). Audio input to the model is collected using audio devices ([`getUserMedia`](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia)), and media streams are added as tracks to to the peer connection.

The example code from the [WebRTC connection guide](/docs/guides/realtime-webrtc) shows a basic example of configuring both local and remote audio:

```javascript
// Create a peer connection
const pc = new RTCPeerConnection();

// Set up to play remote audio from the model
const audioEl = document.createElement("audio");
audioEl.autoplay = true;
pc.ontrack = e => audioEl.srcObject = e.streams[0];

// Add local audio track for microphone input in the browser
const ms = await navigator.mediaDevices.getUserMedia({
  audio: true
});
pc.addTrack(ms.getTracks()[0]);
```

The snippet above should suffice for simple integrations with the Realtime API, but there's much more that can be done with the WebRTC APIs. For more examples of different kinds of user interfaces, check out the [WebRTC samples](https://github.com/webrtc/samples) repository. Live demos of these samples can also be [found here](https://webrtc.github.io/samples/).

Using [media captures and streams](https://developer.mozilla.org/en-US/docs/Web/API/Media_Capture_and_Streams_API) in the browser enables you to do things like mute and unmute microphones, select which device to collect input from, and more.

### Client and server events for audio in WebRTC

By default, WebRTC clients don't need to send any client events to the Realtime API to start sending audio inputs. Once a local audio track is added to the peer connection, your users can just start talking!

However, WebRTC clients still receive a number of server-sent lifecycle events as audio is moving back and forth between client and server over the peer connection. An incomplete sample of server events that are sent during a WebRTC session:

*   When input is sent over the local media track, you will receive [`input_audio_buffer.speech_started`](/docs/api-reference/realtime-server-events/input_audio_buffer/speech_started) events from the server.
*   When local audio input stops, you'll receive the [`input_audio_buffer.speech_stopped`](/docs/api-reference/realtime-server-events/input_audio_buffer/speech_started) event.
*   You'll receive [delta events for the in-progress audio transcript](/docs/api-reference/realtime-server-events/response/audio_transcript/delta).
*   You'll receive a [`response.done`](/docs/api-reference/realtime-server-events/response/done) event when the model has transcribed and completed sending a response.

Manipulating WebRTC APIs for media streams may give you all the control you need in your application. However, it may occasionally be necessary to use lower-level interfaces for audio input and output. Refer to the WebSockets section below for more information and a listing of events required for granular audio input handling.

### Handling audio with WebSockets

When sending and receiving audio over a WebSocket, you will have a bit more work to do in order to send media from the client, and receive media from the server. Below, you'll find a table describing the flow of events during a WebSocket session that are necessary to send and receive audio over the WebSocket.

The events below are given in lifecycle order, though some events (like the `delta` events) may happen concurrently.

||
|Session initialization|session.update|session.createdsession.updated|
|User audio input|conversation.item.create  (send whole audio message)input_audio_buffer.append  (stream audio in chunks)input_audio_buffer.commit  (used when VAD is disabled)response.create  (used when VAD is disabled)|input_audio_buffer.speech_startedinput_audio_buffer.speech_stoppedinput_audio_buffer.committed|
|Server audio output|input_audio_buffer.clear  (used when VAD is disabled)|conversation.item.createdresponse.createdresponse.output_item.createdresponse.content_part.addedresponse.audio.deltaresponse.audio_transcript.deltaresponse.text.deltaresponse.audio.doneresponse.audio_transcript.doneresponse.text.doneresponse.content_part.doneresponse.output_item.doneresponse.donerate_limits.updated|

### Streaming audio input to the server

To stream audio input to the server, you can use the [`input_audio_buffer.append`](/docs/api-reference/realtime-client-events/input_audio_buffer/append) client event. This event requires you to send chunks of **Base64-encoded audio bytes** to the Realtime API over the socket. Each chunk cannot exceed 15 MB in size.

The format of the input chunks can be configured either for the entire session, or per response.

*   Session: `session.input_audio_format` in [`session.update`](/docs/api-reference/realtime-client-events/session/update)
*   Response: `response.input_audio_format` in [`response.create`](/docs/api-reference/realtime-client-events/response/create)

Append audio input bytes to the conversation

```javascript
import fs from 'fs';
import decodeAudio from 'audio-decode';

// Converts Float32Array of audio data to PCM16 ArrayBuffer
function floatTo16BitPCM(float32Array) {
  const buffer = new ArrayBuffer(float32Array.length * 2);
  const view = new DataView(buffer);
  let offset = 0;
  for (let i = 0; i < float32Array.length; i++, offset += 2) {
    let s = Math.max(-1, Math.min(1, float32Array[i]));
    view.setInt16(offset, s < 0 ? s * 0x8000 : s * 0x7fff, true);
  }
  return buffer;
}

// Converts a Float32Array to base64-encoded PCM16 data
base64EncodeAudio(float32Array) {
  const arrayBuffer = floatTo16BitPCM(float32Array);
  let binary = '';
  let bytes = new Uint8Array(arrayBuffer);
  const chunkSize = 0x8000; // 32KB chunk size
  for (let i = 0; i < bytes.length; i += chunkSize) {
    let chunk = bytes.subarray(i, i + chunkSize);
    binary += String.fromCharCode.apply(null, chunk);
  }
  return btoa(binary);
}

// Fills the audio buffer with the contents of three files,
// then asks the model to generate a response.
const files = [
  './path/to/sample1.wav',
  './path/to/sample2.wav',
  './path/to/sample3.wav'
];

for (const filename of files) {
  const audioFile = fs.readFileSync(filename);
  const audioBuffer = await decodeAudio(audioFile);
  const channelData = audioBuffer.getChannelData(0);
  const base64Chunk = base64EncodeAudio(channelData);
  ws.send(JSON.stringify({
    type: 'input_audio_buffer.append',
    audio: base64Chunk
  }));
});

ws.send(JSON.stringify({type: 'input_audio_buffer.commit'}));
ws.send(JSON.stringify({type: 'response.create'}));
```

```python
import base64
import json
import struct
import soundfile as sf
from websocket import create_connection

# ... create websocket-client named ws ...

def float_to_16bit_pcm(float32_array):
    clipped = [max(-1.0, min(1.0, x)) for x in float32_array]
    pcm16 = b''.join(struct.pack('<h', int(x * 32767)) for x in clipped)
    return pcm16

def base64_encode_audio(float32_array):
    pcm_bytes = float_to_16bit_pcm(float32_array)
    encoded = base64.b64encode(pcm_bytes).decode('ascii')
    return encoded

files = [
    './path/to/sample1.wav',
    './path/to/sample2.wav',
    './path/to/sample3.wav'
]

for filename in files:
    data, samplerate = sf.read(filename, dtype='float32')  
    channel_data = data[:, 0] if data.ndim > 1 else data
    base64_chunk = base64_encode_audio(channel_data)
    
    # Send the client event
    event = {
        "type": "input_audio_buffer.append",
        "audio": base64_chunk
    }
    ws.send(json.dumps(event))
```

### Send full audio messages

It is also possible to create conversation messages that are full audio recordings. Use the [`conversation.item.create`](/docs/api-reference/realtime-client-events/conversation/item/create) client event to create messages with `input_audio` content.

Create full audio input conversation items

```javascript
const fullAudio = "<a base64-encoded string of audio bytes>";

const event = {
  type: "conversation.item.create",
  item: {
    type: "message",
    role: "user",
    content: [
      {
        type: "input_audio",
        audio: fullAudio,
      },
    ],
  },
};

// WebRTC data channel and WebSocket both have .send()
dataChannel.send(JSON.stringify(event));
```

```python
fullAudio = "<a base64-encoded string of audio bytes>"

event = {
    "type": "conversation.item.create",
    "item": {
        "type": "message",
        "role": "user",
        "content": [
            {
                "type": "input_audio",
                "audio": fullAudio,
            }
        ],
    },
}

ws.send(json.dumps(event))
```

### Working with audio output from a WebSocket

**To play output audio back on a client device like a web browser, we recommend using WebRTC rather than WebSockets**. WebRTC will be more robust sending media to client devices over uncertain network conditions.

But to work with audio output in server-to-server applications using a WebSocket, you will need to listen for [`response.audio.delta`](/docs/api-reference/realtime-server-events/response/audio/delta) events containing the Base64-encoded chunks of audio data from the model. You will either need to buffer these chunks and write them out to a file, or maybe immediately stream them to another source like [a phone call with Twilio](https://www.twilio.com/en-us/blog/twilio-openai-realtime-api-launch-integration).

Note that the [`response.audio.done`](/docs/api-reference/realtime-server-events/response/audio/done) and [`response.done`](/docs/api-reference/realtime-server-events/response/done) events won't actually contain audio data in them - just audio content transcriptions. To get the actual bytes, you'll need to listen for the [`response.audio.delta`](/docs/api-reference/realtime-server-events/response/audio/delta) events.

The format of the output chunks can be configured either for the entire session, or per response.

*   Session: `session.output_audio_format` in [`session.update`](/docs/api-reference/realtime-client-events/session/update)
*   Response: `response.output_audio_format` in [`response.create`](/docs/api-reference/realtime-client-events/response/create)

Listen for response.audio.delta events

```javascript
function handleEvent(e) {
  const serverEvent = JSON.parse(e.data);
  if (serverEvent.type === "response.audio.delta") {
    // Access Base64-encoded audio chunks
    // console.log(serverEvent.delta);
  }
}

// Listen for server messages (WebSocket)
ws.on("message", handleEvent);
```

```python
def on_message(ws, message):
    server_event = json.loads(message)
    if server_event.type == "response.audio.delta":
        # Access Base64-encoded audio chunks:
        # print(server_event.delta)
```

Voice activity detection (VAD)
------------------------------

By default, Realtime sessions have **voice activity detection (VAD)** enabled, which means the API will determine when the user has started or stopped speaking, and automatically start to respond. The behavior and sensitivity of VAD can be configured through the `session.turn_detection` property of the [`session.update`](/docs/api-reference/realtime-client-events/session/update) client event.

VAD can be disabled by setting `turn_detection` to `null` with the [`session.update`](/docs/api-reference/realtime-client-events/session/update) client event. This can be useful for interfaces where you would like to take granular control over audio input, like [push to talk](https://en.wikipedia.org/wiki/Push-to-talk) interfaces.

When VAD is disabled, the client will have to manually emit some additional client events to trigger audio responses:

*   Manually send [`input_audio_buffer.commit`](/docs/api-reference/realtime-client-events/input_audio_buffer/commit), which will create a new user input item for the conversation.
*   Manually send [`response.create`](/docs/api-reference/realtime-client-events/response/create) to trigger an audio response from the model.
*   Send [`input_audio_buffer.clear`](/docs/api-reference/realtime-client-events/input_audio_buffer/clear) before beginning a new user input.

### Keep VAD, but disable automatic responses

If you would like to keep VAD mode enabled, but would just like to retain the ability to manually decide when a response is generated, you can set `turn_detection.create_response` to `false` with the [`session.update`](/docs/api-reference/realtime-client-events/session/update) client event. This will retain all the behavior of VAD, but still require you to manually send a [`response.create`](/docs/api-reference/realtime-client-events/response/create) event before a response is generated by the model.

This can be useful for moderation or input validation, where you're comfortable trading a bit more latency in the interaction for control over inputs.

Create responses outside the default conversation
-------------------------------------------------

By default, all responses generated during a session are added to the session's conversation state (the "default conversation"). However, you may want to generate model responses outside the context of the session's default conversation, or have multiple responses generated concurrently. You might also want to have more granular control over which conversation items are considered while the model generates a response (e.g. only the last N number of turns).

Generating "out-of-band" responses which are not added to the default conversation state is possible by setting the `response.conversation` field to the string `none` when creating a response with the [`response.create`](/docs/api-reference/realtime-client-events/response/create) client event.

When creating an out-of-band response, you will probably also want some way to identify which server-sent events pertain to this response. You can provide `metadata` for your model response that will help you identify which response is being generated for this client-sent event.

Create an out-of-band model response

```javascript
const prompt = `
Analyze the conversation so far. If it is related to support, output
"support". If it is related to sales, output "sales".
`;

const event = {
  type: "response.create",
  response: {
    // Setting to "none" indicates the response is out of band
    // and will not be added to the default conversation
    conversation: "none",

    // Set metadata to help identify responses sent back from the model
    metadata: { topic: "classification" },
    
    // Set any other available response fields
    modalities: [ "text" ],
    instructions: prompt,
  },
};

// WebRTC data channel and WebSocket both have .send()
dataChannel.send(JSON.stringify(event));
```

```python
prompt = """
Analyze the conversation so far. If it is related to support, output
"support". If it is related to sales, output "sales".
"""

event = {
    "type": "response.create",
    "response": {
        # Setting to "none" indicates the response is out of band,
        # and will not be added to the default conversation
        "conversation": "none",

        # Set metadata to help identify responses sent back from the model
        "metadata": { "topic": "classification" },

        # Set any other available response fields
        "modalities": [ "text" ],
        "instructions": prompt,
    },
}

ws.send(json.dumps(event))
```

Now, when you listen for the [`response.done`](/docs/api-reference/realtime-server-events/response/done) server event, you can identify the result of your out-of-band response.

Create an out-of-band model response

```javascript
function handleEvent(e) {
  const serverEvent = JSON.parse(e.data);
  if (
    serverEvent.type === "response.done" &&
    serverEvent.response.metadata?.topic === "classification"
  ) {
    // this server event pertained to our OOB model response
    console.log(serverEvent.response.output[0]);
  }
}

// Listen for server messages (WebRTC)
dataChannel.addEventListener("message", handleEvent);

// Listen for server messages (WebSocket)
// ws.on("message", handleEvent);
```

```python
def on_message(ws, message):
    server_event = json.loads(message)
    topic = ""

    # See if metadata is present
    try:
        topic = server_event.response.metadata.topic
    except AttributeError:
        print("topic not set")
    
    if server_event.type == "response.done" and topic == "classification":
        # this server event pertained to our OOB model response
        print(server_event.response.output[0])
```

### Create a custom context for responses

You can also construct a custom context that the model will use to generate a response, outside the default/current conversation. This can be done using the `input` array on a [`response.create`](/docs/api-reference/realtime-client-events/response/create) client event. You can use new inputs, or reference existing input items in the conversation by ID.

Listen for out-of-band model response with custom context

```javascript
const event = {
  type: "response.create",
  response: {
    conversation: "none",
    metadata: { topic: "pizza" },
    modalities: [ "text" ],

    // Create a custom input array for this request with whatever context
    // is appropriate
    input: [
      // potentially include existing conversation items:
      {
        type: "item_reference",
        id: "some_conversation_item_id"
      },
      {
        type: "message",
        role: "user",
        content: [
          {
            type: "input_text",
            text: "Is it okay to put pineapple on pizza?",
          },
        ],
      },
    ],
  },
};

// WebRTC data channel and WebSocket both have .send()
dataChannel.send(JSON.stringify(event));
```

```python
event = {
    "type": "response.create",
    "response": {
        "conversation": "none",
        "metadata": { "topic": "pizza" },
        "modalities": [ "text" ],

        # Create a custom input array for this request with whatever 
        # context is appropriate
        "input": [
            # potentially include existing conversation items:
            {
                "type": "item_reference",
                "id": "some_conversation_item_id"
            },

            # include new content as well
            {
                "type": "message",
                "role": "user",
                "content": [
                    {
                        "type": "input_text",
                        "text": "Is it okay to put pineapple on pizza?",
                    }
                ],
            }
        ],
    },
}

ws.send(json.dumps(event))
```

### Create responses with no context

You can also insert responses into the default conversation, ignoring all other instructions and context. Do this by setting `input` to an empty array.

Insert no-context model responses into the default conversation

```javascript
const prompt = `
Say exactly the following:
I'm a little teapot, short and stout! 
This is my handle, this is my spout!
`;

const event = {
  type: "response.create",
  response: {
    // An empty input array removes existing context
    input: [],
    instructions: prompt,
  },
};

// WebRTC data channel and WebSocket both have .send()
dataChannel.send(JSON.stringify(event));
```

```python
prompt = """
Say exactly the following:
I'm a little teapot, short and stout! 
This is my handle, this is my spout!
"""

event = {
    "type": "response.create",
    "response": {
        # An empty input array removes all prior context
        "input": [],
        "instructions": prompt,
    },
}

ws.send(json.dumps(event))
```

Function calling
----------------

The Realtime models also support **function calling**, which enables you to execute custom code to extend the capabilities of the model. Here's how it works at a high level:

1.  When [updating the session](/docs/api-reference/realtime-client-events/session/update) or [creating a response](/docs/api-reference/realtime-client-events/response/create), you can specify a list of available functions for the model to call.
2.  If when processing input, the model determines it should make a function call, it will add items to the conversation representing arguments to a function call.
3.  When the client detects conversation items that contain function call arguments, it will execute custom code using those arguments
4.  When the custom code has been executed, the client will create new conversation items that contain the output of the function call, and ask the model to respond.

Let's see how this would work in practice by adding a callable function that will provide today's horoscope to users of the model. We'll show the shape of the client event objects that need to be sent, and what the server will emit in turn.

### Configure callable functions

First, we must give the model a selection of functions it can call based on user input. Available functions can be configured either at the session level, or the individual response level.

*   Session: `session.tools` property in [`session.update`](/docs/api-reference/realtime-client-events/session/update)
*   Response: `response.tools` property in [`response.create`](/docs/api-reference/realtime-client-events/response/create)

Here's an example client event payload for a `session.update` that configures a horoscope generation function, that takes a single argument (the astrological sign for which the horoscope should be generated):

[`session.update`](/docs/api-reference/realtime-client-events/session/update)

```json
{
  "type": "session.update",
  "session": {
    "tools": [
      {
        "type": "function",
        "name": "generate_horoscope",
        "description": "Give today's horoscope for an astrological sign.",
        "parameters": {
          "type": "object",
          "properties": {
            "sign": {
              "type": "string",
              "description": "The sign for the horoscope.",
              "enum": [
                "Aries",
                "Taurus",
                "Gemini",
                "Cancer",
                "Leo",
                "Virgo",
                "Libra",
                "Scorpio",
                "Sagittarius",
                "Capricorn",
                "Aquarius",
                "Pisces"
              ]
            }
          },
          "required": ["sign"]
        }
      }
    ],
    "tool_choice": "auto",
  }
}
```

The `description` fields for the function and the parameters help the model choose whether or not to call the function, and what data to include in each parameter. If the model receives input that indicates the user wants their horoscope, it will call this function with a `sign` parameter.

### Detect when the model wants to call a function

Based on inputs to the model, the model may decide to call a function in order to generate the best response. Let's say our application adds the following conversation item and attempts to generate a response:

[`conversation.item.create`](/docs/api-reference/realtime-client-events/conversation/item/create)

```json
{
  "type": "conversation.item.create",
  "item": {
    "type": "message",
    "role": "user",
    "content": [
      {
        "type": "input_text",
        "text": "What is my horoscope? I am an aquarius."
      }
    ]
  }
}
```

Followed by a client event to generate a response:

[`response.create`](/docs/api-reference/realtime-client-events/response/create)

```json
{
  "type": "response.create"
}
```

Instead of immediately returning a text or audio response, the model will instead generate a response that contains the arguments that should be passed to a function in the developer's application. You can listen for realtime updates to function call arguments using the [`response.function_call_arguments.delta`](/docs/api-reference/realtime-server-events/response/function_call_arguments/delta) server event, but `response.done` will also have the complete data we need to call our function.

[`response.done`](/docs/api-reference/realtime-server-events/response/done)

```json
{
  "type": "response.done",
  "event_id": "event_AeqLA8iR6FK20L4XZs2P6",
  "response": {
    "object": "realtime.response",
    "id": "resp_AeqL8XwMUOri9OhcQJIu9",
    "status": "completed",
    "status_details": null,
    "output": [
      {
        "object": "realtime.item",
        "id": "item_AeqL8gmRWDn9bIsUM2T35",
        "type": "function_call",
        "status": "completed",
        "name": "generate_horoscope",
        "call_id": "call_sHlR7iaFwQ2YQOqm",
        "arguments": "{\"sign\":\"Aquarius\"}"
      }
    ],
    "usage": {
      "total_tokens": 541,
      "input_tokens": 521,
      "output_tokens": 20,
      "input_token_details": {
        "text_tokens": 292,
        "audio_tokens": 229,
        "cached_tokens": 0,
        "cached_tokens_details": { "text_tokens": 0, "audio_tokens": 0 }
      },
      "output_token_details": {
        "text_tokens": 20,
        "audio_tokens": 0
      }
    },
    "metadata": null
  }
}
```

In the JSON emitted by the server, we can detect that the model wants to call a custom function:

|Property|Function calling purpose|
|---|---|
|response.output[0].type|When set to function_call, indicates this response contains arguments for a named function call.|
|response.output[0].name|The name of the configured function to call, in this case generate_horoscope|
|response.output[0].arguments|A JSON string containing arguments to the function. In our case, "{\"sign\":\"Aquarius\"}".|
|response.output[0].call_id|A system-generated ID for this function call - you will need this ID to pass a function call result back to the model.|

Given this information, we can execute code in our application to generate the horoscope, and then provide that information back to the model so it can generate a response.

### Provide the results of a function call to the model

Upon receiving a response from the model with arguments to a function call, your application can execute code that satisfies the function call. This could be anything you want, like talking to external APIs or accessing databases.

Once you are ready to give the model the results of your custom code, you can create a new conversation item containing the result via the `conversation.item.create` client event.

[`conversation.item.create`](/docs/api-reference/realtime-client-events/conversation/item/create)

```json
{
  "type": "conversation.item.create",
  "item": {
    "type": "function_call_output",
    "call_id": "call_sHlR7iaFwQ2YQOqm",
    "output": "{\"horoscope\": \"You will soon meet a new friend.\"}"
  }
}
```

*   The conversation item type is `function_call_output`
*   `item.call_id` is the same ID we got back in the `response.done` event above
*   `item.output` is a JSON string containing the results of our function call

Once we have added the conversation item containing our function call results, we again emit the `response.create` event from the client. This will trigger a model response using the data from the function call.

[`response.create`](/docs/api-reference/realtime-client-events/response/create)

```json
{
  "type": "response.create"
}
```

Error handling
--------------

The [`error`](/docs/api-reference/realtime-server-events/error) event is emitted by the server whenever an error condition is encountered on the server during the session. Occasionally, these errors can be traced to a client event that was emitted by your application.

Unlike HTTP requests and responses, where a response is implicitly tied to a request from the client, we need to use an `event_id` property on client events to know when one of them has triggered an error condition on the server. This technique is shown in the code below, where the client attempts to emit an unsupported event type.

```javascript
const event = {
  event_id: "my_awesome_event",
  type: "scooby.dooby.doo",
};

dataChannel.send(JSON.stringify(event));
```

This unsuccessful event sent from the client will emit an error event like the following:

```json
{
  "type": "invalid_request_error",
  "code": "invalid_value",
  "message": "Invalid value: 'scooby.dooby.doo' ...",
  "param": "type",
  "event_id": "my_awesome_event"
}
```

Next steps
----------

Realtime models unlock new possibilities for AI interactions. We can't wait to hear about what you create with the Realtime API! As you continue to explore, here are a few other resources that may be useful.

[

Realtime Console

The Realtime console sample app shows how to exercise function calling, client and server events, and much more.

](https://github.com/openai/openai-realtime-console)[

Event API reference

A complete listing of client and server events in the Realtime API

](/docs/api-reference/realtime-client-events)

Was this page useful?