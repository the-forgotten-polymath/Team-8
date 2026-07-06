// SupabaseConfig.swift
// RSMS — Sales Associate Module
// Replace SUPABASE_URL and SUPABASE_ANON_KEY with your project credentials

import Foundation
import Supabase

// MARK: - Supabase Client (Singleton)

let supabase = SupabaseClient(
    supabaseURL: URL(string: AppConstants.Supabase.projectURL)!,
    supabaseKey: AppConstants.Supabase.anonKey
)
