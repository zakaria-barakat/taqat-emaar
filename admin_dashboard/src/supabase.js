import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://bjrdsbvixmnmnxcsrhvj.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJqcmRzYnZpeG1ubW54Y3NyaHZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEyMTc2NDIsImV4cCI6MjEwNjc5MzY0Mn0.P9te8cGdNtQeI_kELj668mcF33tL3iMaDU26FoX0IC4';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

/**
 * Checks if the current authenticated user has admin privileges
 * by calling the existing database RPC function is_admin().
 */
export async function checkIsAdmin() {
  const { data, error } = await supabase.rpc('is_admin');
  if (error) {
    console.error('Error checking admin status:', error);
    return false;
  }
  return Boolean(data);
}
