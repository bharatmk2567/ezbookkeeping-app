import { Capacitor } from '@capacitor/core';
import { Camera, CameraResultType, CameraSource } from '@capacitor/camera';
import { Share } from '@capacitor/share';
import { Filesystem, Directory, Encoding } from '@capacitor/filesystem';
import { Haptics, ImpactStyle } from '@capacitor/haptics';
import { App } from '@capacitor/app';
import { StatusBar, Style } from '@capacitor/status-bar';
import { SplashScreen } from '@capacitor/splash-screen';
import { Keyboard } from '@capacitor/keyboard';
import { Geolocation } from '@capacitor/geolocation';
import { LocalNotifications } from '@capacitor/local-notifications';
import { SafeArea } from 'capacitor-plugin-safe-area';
import { BiometricAuth } from '@aparajita/capacitor-biometric-auth';

export function isRunningInCapacitor(): boolean {
    return Capacitor.isNativePlatform();
}

export function getPlatform(): string {
    return Capacitor.getPlatform();
}

export async function initializeStatusBar(): Promise<void> {
    if (!isRunningInCapacitor()) return;
    try {
        await StatusBar.setOverlaysWebView({ overlay: false });
        await StatusBar.setStyle({ style: Style.Light });
        await StatusBar.setBackgroundColor({ color: '#c67e48' });
    } catch (e) {
        console.warn('StatusBar init failed:', e);
    }
}

export async function hideSplashScreen(): Promise<void> {
    if (!isRunningInCapacitor()) return;
    try {
        await SplashScreen.hide();
    } catch (e) {
        console.warn('SplashScreen hide failed:', e);
    }
}

export async function getSafeAreaInsets(): Promise<{ top: number; bottom: number; left: number; right: number }> {
    if (!isRunningInCapacitor()) {
        return { top: 0, bottom: 0, left: 0, right: 0 };
    }
    try {
        const result = await SafeArea.getSafeAreaInsets();
        return result.insets;
    } catch (e) {
        console.warn('SafeArea failed:', e);
        return { top: 0, bottom: 0, left: 0, right: 0 };
    }
}

export async function capturePhoto(): Promise<{ data: string; format: string } | null> {
    if (!isRunningInCapacitor()) return null;
    try {
        const image = await Camera.getPhoto({
            quality: 85,
            allowEditing: false,
            resultType: CameraResultType.Base64,
            source: CameraSource.Prompt,
            width: 1920,
            height: 1920,
        });
        return {
            data: image.base64String || '',
            format: image.format || 'jpeg',
        };
    } catch (e: any) {
        if (e.message?.includes('User cancelled')) return null;
        console.warn('Camera capture failed:', e);
        return null;
    }
}

export async function pickImageFromGallery(): Promise<{ data: string; format: string } | null> {
    if (!isRunningInCapacitor()) return null;
    try {
        const image = await Camera.getPhoto({
            quality: 85,
            allowEditing: false,
            resultType: CameraResultType.Base64,
            source: CameraSource.Photos,
            width: 1920,
            height: 1920,
        });
        return {
            data: image.base64String || '',
            format: image.format || 'jpeg',
        };
    } catch (e: any) {
        if (e.message?.includes('User cancelled')) return null;
        console.warn('Gallery pick failed:', e);
        return null;
    }
}

export async function shareData(options: {
    title?: string;
    text?: string;
    url?: string;
}): Promise<boolean> {
    if (!isRunningInCapacitor()) return false;
    try {
        await Share.share({
            title: options.title,
            text: options.text,
            url: options.url,
        });
        return true;
    } catch (e: any) {
        if (e.message?.includes('cancelled')) return false;
        console.warn('Share failed:', e);
        return false;
    }
}

export async function saveFileToDownloads(options: {
    filename: string;
    data: string;
    encoding?: Encoding;
}): Promise<boolean> {
    if (!isRunningInCapacitor()) return false;
    try {
        await Filesystem.writeFile({
            path: options.filename,
            data: options.data,
            directory: Directory.Documents,
            encoding: options.encoding || Encoding.UTF8,
        });
        return true;
    } catch (e) {
        console.warn('File save failed:', e);
        return false;
    }
}

export async function triggerHapticImpact(style: 'LIGHT' | 'MEDIUM' | 'HEAVY' = 'LIGHT'): Promise<void> {
    if (!isRunningInCapacitor()) return;
    try {
        const impactStyle = style === 'HEAVY' ? ImpactStyle.Heavy
            : style === 'MEDIUM' ? ImpactStyle.Medium
            : ImpactStyle.Light;
        await Haptics.impact({ style: impactStyle });
    } catch (e) {
        // silent fail for haptics
    }
}

export async function triggerHapticNotification(type: 'SUCCESS' | 'WARNING' | 'ERROR' = 'SUCCESS'): Promise<void> {
    if (!isRunningInCapacitor()) return;
    try {
        const hapticsModule = await import('@capacitor/haptics');
        const notifType = type === 'SUCCESS' ? hapticsModule.NotificationType.Success
            : type === 'WARNING' ? hapticsModule.NotificationType.Warning
            : hapticsModule.NotificationType.Error;
        await Haptics.notification({ type: notifType });
    } catch (e) {
        // silent fail
    }
}

function biometryTypeToString(type: number): string {
    switch (type) {
        case 1: return 'touchId';
        case 2: return 'FaceID';
        case 3: return 'fingerprint';
        case 4: return 'face';
        case 5: return 'iris';
        default: return 'none';
    }
}

export async function checkBiometricAvailability(): Promise<{
    available: boolean;
    biometryType: string;
    hasHardware: boolean;
    isEnrolled: boolean;
}> {
    if (!isRunningInCapacitor()) {
        return { available: false, biometryType: 'none', hasHardware: false, isEnrolled: false };
    }
    try {
        const result = await BiometricAuth.checkBiometry();
        return {
            available: result.isAvailable,
            biometryType: biometryTypeToString(result.biometryType),
            hasHardware: result.biometryType !== 0,
            isEnrolled: result.isAvailable,
        };
    } catch (e) {
        return { available: false, biometryType: 'none', hasHardware: false, isEnrolled: false };
    }
}

export async function authenticateWithBiometric(options?: {
    reason?: string;
    title?: string;
    subtitle?: string;
}): Promise<boolean> {
    if (!isRunningInCapacitor()) return false;
    try {
        await BiometricAuth.authenticate({
            reason: options?.reason || 'Authenticate to access ezBookkeeping',
            cancelTitle: 'Cancel',
            allowDeviceCredential: true,
            androidTitle: options?.title || 'Biometric Authentication',
            androidSubtitle: options?.subtitle || 'Verify your identity',
        });
        return true;
    } catch (e: any) {
        if (e.message?.includes('cancelled') || e.message?.includes('User')) return false;
        console.warn('Biometric auth failed:', e);
        return false;
    }
}

export async function getCurrentPosition(): Promise<{
    latitude: number;
    longitude: number;
    accuracy: number;
} | null> {
    if (!isRunningInCapacitor()) return null;
    try {
        const permissions = await Geolocation.requestPermissions();
        if (permissions.location !== 'granted') return null;

        const position = await Geolocation.getCurrentPosition({
            enableHighAccuracy: true,
            timeout: 10000,
        });
        return {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracy: position.coords.accuracy,
        };
    } catch (e) {
        console.warn('Geolocation failed:', e);
        return null;
    }
}

export async function scheduleLocalNotification(options: {
    title: string;
    body: string;
    id?: number;
    schedule?: { at: Date };
}): Promise<void> {
    if (!isRunningInCapacitor()) return;
    try {
        const permission = await LocalNotifications.requestPermissions();
        if (permission.display !== 'granted') return;

        await LocalNotifications.schedule({
            notifications: [{
                title: options.title,
                body: options.body,
                id: options.id || Date.now(),
                schedule: options.schedule,
                smallIcon: 'ic_stat_icon_config_sample',
                iconColor: '#c67e48',
            }],
        });
    } catch (e) {
        console.warn('Local notification failed:', e);
    }
}

export async function cancelAllNotifications(): Promise<void> {
    if (!isRunningInCapacitor()) return;
    try {
        const pending = await LocalNotifications.getPending();
        if (pending.notifications.length > 0) {
            await LocalNotifications.cancel(pending);
        }
    } catch (e) {
        // silent
    }
}

export async function getAppInfo(): Promise<{
    name: string;
    version: string;
    build: string;
} | null> {
    if (!isRunningInCapacitor()) return null;
    try {
        const info = await App.getInfo();
        return {
            name: info.name,
            version: info.version,
            build: info.build,
        };
    } catch (e) {
        return null;
    }
}

export function configureKeyboard(): void {
    if (!isRunningInCapacitor()) return;
    try {
        Keyboard.addListener('keyboardWillShow', (info) => {
            document.body.style.paddingBottom = `${info.keyboardHeight}px`;
        });
        Keyboard.addListener('keyboardWillHide', () => {
            document.body.style.paddingBottom = '0px';
        });
    } catch (e) {
        // silent
    }
}

export async function readFileFromDevice(): Promise<{ data: string; name: string } | null> {
    if (!isRunningInCapacitor()) return null;
    try {
        const { FilePicker } = await import('@capawesome/capacitor-file-picker');
        const result = await FilePicker.pickFiles({
            limit: 1,
            readData: true,
        });
        if (result.files.length > 0) {
            const file = result.files[0];
            if (file) {
                return {
                    data: file.data || '',
                    name: file.name || 'unknown',
                };
            }
        }
        return null;
    } catch (e: any) {
        if (e.message?.includes('cancelled')) return null;
        console.warn('File picker failed:', e);
        return null;
    }
}
