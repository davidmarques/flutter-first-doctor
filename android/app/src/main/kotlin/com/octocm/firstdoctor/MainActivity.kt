package com.octocm.firstdoctor

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable edge-to-edge display for all API levels
        // This properly handles Android 15+ requirements while maintaining backwards compatibility
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
