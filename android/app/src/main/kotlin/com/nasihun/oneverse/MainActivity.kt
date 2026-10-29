package com.nasihun.oneverse

import com.ryanheise.audioservice.AudioServiceActivity

// AudioServiceActivity keeps the Flutter engine shared with the background
// playback service, so the notification and lock screen stay in sync.
class MainActivity : AudioServiceActivity()
