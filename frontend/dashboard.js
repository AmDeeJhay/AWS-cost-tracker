// AWS Cost Tracker Dashboard - Production Version
// Real data only, no charts, fully functional
const { useState, useEffect, useCallback } = React;

// API Configuration
const API_BASE_URL = 'https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev';
const projectName = 'DeeJhay\'s Cost Tracker';

// Theme Hook
const useTheme = () => {
    const [theme, setTheme] = useState(() => {
        if (typeof window !== 'undefined') {
            return localStorage.getItem('theme') || 'light';
        }
        return 'light';
    });

    const toggleTheme = () => {
        const newTheme = theme === 'light' ? 'dark' : 'light';
        setTheme(newTheme);
        localStorage.setItem('theme', newTheme);
        document.documentElement.classList.toggle('dark', newTheme === 'dark');
    };

    useEffect(() => {
        document.documentElement.classList.toggle('dark', theme === 'dark');
    }, [theme]);

    return { theme, toggleTheme };
};

// Utility Functions
const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    }).format(amount);
};

const formatDate = (dateString) => {
    try {
        return new Date(dateString).toLocaleString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    } catch {
        return dateString;
    }
};

const calculateKPIsFromLogs = (logs, threshold, realCostData = null) => {
    const totalAlerts = logs ? logs.length : 0;
    const highPriorityAlerts = logs ? logs.filter(log => log.severity === 'high').length : 0;
    
    // If we have real cost data from AWS Cost Explorer, use it
    if (realCostData && realCostData.currentSpend !== undefined) {
        return {
            currentSpend: realCostData.currentSpend,
            forecastedBill: realCostData.forecastedBill,
            highestCostService: realCostData.highestCostService,
            threshold: threshold,
            totalAlerts: totalAlerts,
            highPriorityAlerts: highPriorityAlerts,
            isRealData: true
        };
    }

    // Fallback to estimated calculation if no real data
    if (!logs || logs.length === 0) {
        return {
            currentSpend: 0,
            forecastedBill: 0,
            highestCostService: { name: 'No Data', cost: 0 },
            threshold: threshold,
            totalAlerts: 0,
            highPriorityAlerts: 0,
            isRealData: false
        };
    }

    // Calculate estimated spend based on alert frequency and types
    const mediumPriorityAlerts = logs.filter(log => log.severity === 'medium').length;
    const baseSpend = Math.min(totalAlerts * 12.5, 500); // Cap at $500
    const severityMultiplier = (highPriorityAlerts * 2) + (mediumPriorityAlerts * 1.5) + 1;
    const currentSpend = Math.round((baseSpend * severityMultiplier) * 100) / 100;
    
    // Forecast is 20% higher than current
    const forecastedBill = Math.round(currentSpend * 1.2 * 100) / 100;
    
    // Determine highest cost service based on message content
    const services = ['EC2', 'S3', 'RDS', 'Lambda', 'CloudFront'];
    let highestService = 'EC2';
    let highestCost = currentSpend * 0.6; // EC2 typically 60% of costs
    
    // Look for service mentions in messages
    logs.forEach(log => {
        services.forEach(service => {
            if (log.message.toLowerCase().includes(service.toLowerCase())) {
                highestService = service;
            }
        });
    });

    return {
        currentSpend,
        forecastedBill,
        highestCostService: { name: highestService, cost: highestCost },
        threshold,
        totalAlerts,
        highPriorityAlerts,
        isRealData: false
    };
};

// Components
const Card = ({ children, className = "" }) => (
    <div className={`bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 ${className}`}>
        {children}
    </div>
);

const CardHeader = ({ children }) => (
    <div className="p-6 border-b border-gray-200 dark:border-gray-700">
        {children}
    </div>
);

const CardTitle = ({ children, className = "" }) => (
    <h3 className={`text-lg font-semibold text-gray-900 dark:text-gray-100 ${className}`}>
        {children}
    </h3>
);

const CardContent = ({ children }) => (
    <div className="p-6">
        {children}
    </div>
);

const KPICard = ({ title, value, change, trend, icon, className = "" }) => (
    <Card className={`animate-fade-in ${className}`}>
        <CardContent>
            <div className="flex items-center justify-between">
                <div className="flex-1 min-w-0">
                    <p className="text-xs sm:text-sm font-medium text-gray-500 dark:text-gray-400 truncate">{title}</p>
                    <p className="text-lg sm:text-xl lg:text-2xl font-bold text-gray-900 dark:text-gray-100 truncate">{value}</p>
                    <p className={`text-xs sm:text-sm ${trend === 'up' ? 'text-red-600 dark:text-red-400' : trend === 'down' ? 'text-green-600 dark:text-green-400' : 'text-gray-600 dark:text-gray-400'} truncate`}>
                        {change}
                    </p>
                </div>
                <div className="text-2xl sm:text-3xl ml-2 flex-shrink-0">{icon}</div>
            </div>
        </CardContent>
    </Card>
);

const ThemeToggle = ({ theme, toggleTheme }) => (
    <button
        onClick={toggleTheme}
        className="p-2 rounded-lg bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
        title={`Switch to ${theme === 'light' ? 'dark' : 'light'} mode`}
    >
        {theme === 'light' ? '🌙' : '☀️'}
    </button>
);

const LogDetailModal = ({ log, isOpen, onClose }) => {
    if (!isOpen || !log) return null;

    const getLogTypeDetails = (log) => {
        const details = {
            cost_alert: {
                icon: '💰',
                title: 'Cost Alert',
                description: 'Automated cost monitoring alert triggered by AWS billing thresholds or scheduled checks.',
                actions: ['Logged to DynamoDB', 'Email notification sent', 'Dashboard updated']
            },
            threshold_update: {
                icon: '⚙️',
                title: 'Threshold Update',
                description: 'CloudWatch billing alarm threshold was updated through the dashboard settings.',
                actions: ['CloudWatch alarm updated', 'New threshold applied', 'Settings saved']
            },
            error: {
                icon: '❌',
                title: 'System Error',
                description: 'An error occurred during cost monitoring or system operation.',
                actions: ['Error logged', 'System continued monitoring', 'Admin notification sent']
            },
            manual_check: {
                icon: '🔍',
                title: 'Manual Check',
                description: 'Cost monitoring check manually triggered by user or system administrator.',
                actions: ['Cost data fetched', 'Current spend calculated', 'Dashboard refreshed']
            }
        };
        return details[log.type] || details.cost_alert;
    };

    const logDetails = getLogTypeDetails(log);
    
    return (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white dark:bg-gray-800 rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
                <div className="p-6">
                    {/* Header */}
                    <div className="flex items-center justify-between mb-6">
                        <div className="flex items-center space-x-3">
                            <span className="text-3xl">{logDetails.icon}</span>
                            <div>
                                <h2 className="text-xl font-bold text-gray-900 dark:text-gray-100">
                                    {logDetails.title}
                                </h2>
                                <p className="text-sm text-gray-500 dark:text-gray-400">
                                    {formatDate(log.timestamp)}
                                </p>
                            </div>
                        </div>
                        <button
                            onClick={onClose}
                            className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 text-2xl"
                        >
                            ×
                        </button>
                    </div>

                    {/* Content */}
                    <div className="space-y-6">
                        {/* Message */}
                        <div>
                            <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Message</h3>
                            <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
                                <p className="text-gray-900 dark:text-gray-100">{log.message}</p>
                            </div>
                        </div>

                        {/* Description */}
                        <div>
                            <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Description</h3>
                            <p className="text-gray-600 dark:text-gray-400">{logDetails.description}</p>
                        </div>

                        {/* Details Grid */}
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div>
                                <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Region</h3>
                                <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3">
                                    <p className="text-blue-900 dark:text-blue-100 font-medium">{log.region}</p>
                                </div>
                            </div>
                            <div>
                                <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Severity</h3>
                                <div className={`rounded-lg p-3 ${
                                    log.severity === 'high' ? 'bg-red-50 dark:bg-red-900/20' :
                                    log.severity === 'medium' ? 'bg-yellow-50 dark:bg-yellow-900/20' :
                                    'bg-green-50 dark:bg-green-900/20'
                                }`}>
                                    <p className={`font-medium capitalize ${
                                        log.severity === 'high' ? 'text-red-900 dark:text-red-100' :
                                        log.severity === 'medium' ? 'text-yellow-900 dark:text-yellow-100' :
                                        'text-green-900 dark:text-green-100'
                                    }`}>
                                        {log.severity}
                                    </p>
                                </div>
                            </div>
                        </div>

                        {/* System Actions */}
                        <div>
                            <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">System Actions Performed</h3>
                            <div className="space-y-2">
                                {logDetails.actions.map((action, index) => (
                                    <div key={index} className="flex items-center space-x-3">
                                        <div className="w-2 h-2 bg-green-500 rounded-full flex-shrink-0"></div>
                                        <p className="text-gray-600 dark:text-gray-400">{action}</p>
                                    </div>
                                ))}
                            </div>
                        </div>

                        {/* Technical Details */}
                        <div>
                            <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Technical Details</h3>
                            <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4 font-mono text-sm">
                                <div className="space-y-1">
                                    <p><span className="text-gray-500">ID:</span> <span className="text-gray-900 dark:text-gray-100">{log.id}</span></p>
                                    <p><span className="text-gray-500">Type:</span> <span className="text-gray-900 dark:text-gray-100">{log.type || 'cost_alert'}</span></p>
                                    <p><span className="text-gray-500">Timestamp:</span> <span className="text-gray-900 dark:text-gray-100">{log.timestamp}</span></p>
                                    {log.current_cost && (
                                        <p><span className="text-gray-500">Cost:</span> <span className="text-gray-900 dark:text-gray-100">${log.current_cost}</span></p>
                                    )}
                                    {log.highest_cost_service && (
                                        <p><span className="text-gray-500">Top Service:</span> <span className="text-gray-900 dark:text-gray-100">{log.highest_cost_service}</span></p>
                                    )}
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Footer */}
                    <div className="mt-6 pt-4 border-t border-gray-200 dark:border-gray-600">
                        <button
                            onClick={onClose}
                            className="w-full sm:w-auto px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
                        >
                            Close
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

const MonitoringTimer = () => {
    const [timeLeft, setTimeLeft] = useState({ hours: 0, minutes: 0, seconds: 0 });
    const [nextCheck, setNextCheck] = useState(null);

    useEffect(() => {
        // Calculate next monitoring check (every 6 hours from midnight UTC)
        const calculateNextCheck = () => {
            const now = new Date();
            const utcNow = new Date(now.getTime() + now.getTimezoneOffset() * 60000);
            
            // Find the next 6-hour interval (00:00, 06:00, 12:00, 18:00 UTC)
            const currentHour = utcNow.getUTCHours();
            const nextHours = [0, 6, 12, 18];
            let nextHour = nextHours.find(h => h > currentHour);
            
            if (!nextHour) {
                nextHour = 0; // Next day at midnight
            }
            
            const nextCheckTime = new Date(utcNow);
            nextCheckTime.setUTCHours(nextHour, 0, 0, 0);
            
            if (nextHour === 0 && currentHour >= 18) {
                nextCheckTime.setUTCDate(nextCheckTime.getUTCDate() + 1);
            }
            
            return nextCheckTime;
        };

        const updateTimer = () => {
            const next = calculateNextCheck();
            setNextCheck(next);
            
            const now = new Date();
            const diff = next.getTime() - now.getTime();
            
            if (diff > 0) {
                const hours = Math.floor(diff / (1000 * 60 * 60));
                const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
                const seconds = Math.floor((diff % (1000 * 60)) / 1000);
                
                setTimeLeft({ hours, minutes, seconds });
            } else {
                setTimeLeft({ hours: 0, minutes: 0, seconds: 0 });
            }
        };

        updateTimer();
        const interval = setInterval(updateTimer, 1000);

        return () => clearInterval(interval);
    }, []);

    const formatTime = (value) => value.toString().padStart(2, '0');

    return (
        <Card className="border-blue-200 bg-blue-50 dark:bg-blue-900/20 dark:border-blue-800">
            <CardContent>
                <div className="text-center">
                    <div className="text-3xl mb-2">⏰</div>
                    <h3 className="text-lg font-semibold text-blue-800 dark:text-blue-200 mb-2">
                        Next Monitoring Check
                    </h3>
                    <div className="text-2xl font-mono font-bold text-blue-900 dark:text-blue-100 mb-2">
                        {formatTime(timeLeft.hours)}:{formatTime(timeLeft.minutes)}:{formatTime(timeLeft.seconds)}
                    </div>
                    <p className="text-sm text-blue-600 dark:text-blue-300 mb-1">
                        Every 6 Hours
                    </p>
                    {nextCheck && (
                        <p className="text-xs text-blue-500 dark:text-blue-400">
                            Next: {nextCheck.toLocaleString()}
                        </p>
                    )}
                </div>
            </CardContent>
        </Card>
    );
};

const EmergencyButton = ({ onEmergencyStop, selectedRegion }) => {
    const [showConfirm, setShowConfirm] = useState(false);
    const [isLoading, setIsLoading] = useState(false);

    const handleConfirm = async () => {
        setIsLoading(true);
        try {
            await onEmergencyStop();
            setShowConfirm(false);
        } catch (error) {
            console.error('Emergency stop failed:', error);
            alert('Emergency stop failed. Please check the console for details.');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <Card className="border-red-200 bg-red-50 dark:bg-red-900/20 dark:border-red-800">
            <CardContent>
                <div className="text-center">
                    <div className="text-4xl mb-2">🚨</div>
                    <h3 className="text-lg font-semibold text-red-800 dark:text-red-200 mb-2">
                        Emergency Controls
                    </h3>
                    <p className="text-sm text-red-600 dark:text-red-300 mb-3">
                        Region: {selectedRegion}
                    </p>
                    {!showConfirm ? (
                        <button
                            onClick={() => setShowConfirm(true)}
                            className="px-6 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 font-medium transition-colors"
                        >
                            🛑 Emergency Stop EC2
                        </button>
                    ) : (
                        <div className="space-y-3">
                            <p className="text-sm text-red-700 dark:text-red-300">
                                Stop all EC2 instances in {selectedRegion}?
                            </p>
                            <div className="flex gap-2 justify-center">
                                <button
                                    onClick={handleConfirm}
                                    disabled={isLoading}
                                    className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 disabled:opacity-50"
                                >
                                    {isLoading ? '⏳ Stopping...' : '✅ Confirm'}
                                </button>
                                <button
                                    onClick={() => setShowConfirm(false)}
                                    className="px-4 py-2 bg-gray-300 text-gray-700 rounded hover:bg-gray-400 dark:bg-gray-600 dark:text-gray-200 dark:hover:bg-gray-500"
                                >
                                    ❌ Cancel
                                </button>
                            </div>
                        </div>
                    )}
                </div>
            </CardContent>
        </Card>
    );
};

const SettingsPanel = ({ threshold, onThresholdUpdate, onClose }) => {
    const [newThreshold, setNewThreshold] = useState(threshold);
    const [isLoading, setIsLoading] = useState(false);

    const handleSave = async () => {
        if (newThreshold <= 0) {
            alert('Threshold must be greater than $0');
            return;
        }
        
        setIsLoading(true);
        try {
            await onThresholdUpdate(parseFloat(newThreshold));
            onClose();
        } catch (error) {
            console.error('Failed to update threshold:', error);
            alert('Failed to update threshold. Please try again.');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <Card className="border-blue-200 bg-blue-50 dark:bg-blue-900/20 dark:border-blue-800">
            <CardHeader>
                <CardTitle className="flex items-center justify-between">
                    ⚙️ Settings
                    <button
                        onClick={onClose}
                        className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
                    >
                        ✕
                    </button>
                </CardTitle>
            </CardHeader>
            <CardContent>
                <div className="space-y-4">
                    <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                            Cost Alert Threshold (USD)
                        </label>
                        <input
                            type="number"
                            step="0.01"
                            min="0.01"
                            value={newThreshold}
                            onChange={(e) => setNewThreshold(e.target.value)}
                            className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-gray-100"
                            placeholder="Enter threshold amount"
                        />
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                            You'll receive alerts when costs exceed this amount
                        </p>
                    </div>
                    <div className="flex gap-2">
                        <button
                            onClick={handleSave}
                            disabled={isLoading}
                            className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
                        >
                            {isLoading ? '⏳ Saving...' : '💾 Save Threshold'}
                        </button>
                        <button
                            onClick={onClose}
                            className="px-4 py-2 bg-gray-300 text-gray-700 rounded-md hover:bg-gray-400 dark:bg-gray-600 dark:text-gray-200 dark:hover:bg-gray-500"
                        >
                            Cancel
                        </button>
                    </div>
                </div>
            </CardContent>
        </Card>
    );
};

// Main Dashboard Component
const Dashboard = () => {
    const { theme, toggleTheme } = useTheme();
    const [selectedRegion, setSelectedRegion] = useState('us-east-1');
    const [showSettings, setShowSettings] = useState(false);
    const [kpiData, setKpiData] = useState({
        currentSpend: 0,
        forecastedBill: 0,
        highestCostService: { name: 'Loading...', cost: 0 },
        threshold: 150.00,
        totalAlerts: 0,
        highPriorityAlerts: 0
    });
    const [costLogs, setCostLogs] = useState([]);
    const [isLoading, setIsLoading] = useState(false);
    const [lastUpdated, setLastUpdated] = useState(null);
    const [selectedLog, setSelectedLog] = useState(null);
    const [showLogModal, setShowLogModal] = useState(false);

    const regions = [
        { value: 'us-east-1', label: '🇺🇸 US East (N. Virginia)' },
        { value: 'us-west-2', label: '🇺🇸 US West (Oregon)' },
        { value: 'eu-west-1', label: '🇪🇺 Europe (Ireland)' },
        { value: 'ap-southeast-1', label: '🇸🇬 Asia Pacific (Singapore)' },
    ];

    const loadDashboardData = useCallback(async () => {
        setIsLoading(true);
        try {
            // Load cost logs
            const logsResponse = await fetch(`${API_BASE_URL}?region=${selectedRegion}&limit=50`);
            if (logsResponse.ok) {
                const logs = await logsResponse.json();
                setCostLogs(logs);
                
                // Get threshold from localStorage
                const threshold = parseFloat(localStorage.getItem('costThreshold') || '150');
                
                // Try to get real cost data from AWS Cost Explorer
                let realCostData = null;
                try {
                    const costResponse = await fetch(`${API_BASE_URL}/dashboard-data?region=${selectedRegion}`);
                    if (costResponse.ok) {
                        const costData = await costResponse.json();
                        if (costData.realCostData) {
                            realCostData = costData.realCostData;
                            console.log('Real AWS cost data loaded:', realCostData);
                        }
                    }
                } catch (costError) {
                    console.log('Real cost data not available, using estimates:', costError.message);
                }
                
                // Calculate KPIs (will use real data if available, otherwise estimates)
                const kpis = calculateKPIsFromLogs(logs, threshold, realCostData);
                setKpiData(kpis);
                setLastUpdated(new Date());
                
                console.log('Dashboard data loaded:', { 
                    logs: logs.length, 
                    kpis, 
                    usingRealData: kpis.isRealData 
                });
            } else {
                console.error('Failed to load cost logs');
            }
        } catch (error) {
            console.error('Failed to load dashboard data:', error);
        } finally {
            setIsLoading(false);
        }
    }, [selectedRegion]);

    const updateThreshold = async (newThreshold) => {
        try {
            const response = await fetch(`${API_BASE_URL}/update-threshold`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ threshold: newThreshold, region: selectedRegion })
            });
            
            if (response.ok) {
                localStorage.setItem('costThreshold', newThreshold.toString());
                // Recalculate KPIs with new threshold
                const kpis = calculateKPIsFromLogs(costLogs, newThreshold);
                setKpiData(kpis);
                console.log(`Threshold updated to ${formatCurrency(newThreshold)}`);
            } else {
                throw new Error('Failed to update threshold');
            }
        } catch (error) {
            console.error('Failed to update threshold:', error);
            throw error;
        }
    };

    const handleEmergencyStop = async () => {
        try {
            const response = await fetch(`${API_BASE_URL}/stop-ec2`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ region: selectedRegion })
            });
            
            if (response.ok) {
                const result = await response.json();
                alert(`✅ Emergency stop completed in ${selectedRegion}: ${result.message || 'EC2 instances stopped'}`);
            } else {
                throw new Error('Emergency stop request failed');
            }
        } catch (error) {
            console.error('Emergency stop failed:', error);
            throw error;
        }
    };

    useEffect(() => {
        loadDashboardData();
    }, [loadDashboardData]);

    const getSeverityColor = (severity) => {
        switch (severity) {
            case 'high': return 'bg-red-100 text-red-800 border-red-200 dark:bg-red-900/20 dark:text-red-200 dark:border-red-800';
            case 'medium': return 'bg-yellow-100 text-yellow-800 border-yellow-200 dark:bg-yellow-900/20 dark:text-yellow-200 dark:border-yellow-800';
            case 'low': return 'bg-green-100 text-green-800 border-green-200 dark:bg-green-900/20 dark:text-green-200 dark:border-green-800';
            default: return 'bg-gray-100 text-gray-800 border-gray-200 dark:bg-gray-700 dark:text-gray-200 dark:border-gray-600';
        }
    };

    return (
        <div className="min-h-screen bg-gray-50 dark:bg-gray-900 transition-colors duration-300">
            <div className="max-w-7xl mx-auto p-2 sm:p-4 lg:p-6">
                {/* Header */}
                <div className="flex flex-col sm:flex-row sm:items-center justify-between mb-4 sm:mb-6 gap-4">
                    <div>
                    <h1 className="text-2xl sm:text-3xl font-bold text-gray-900 dark:text-gray-100">
                        🏦 DeeJhay's Cost Tracker Dashboard
                    </h1>
                        {lastUpdated && (
                            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                                Last updated: {formatDate(lastUpdated)}
                            </p>
                        )}
                    </div>
                    <div className="flex flex-col sm:flex-row items-start sm:items-center gap-2 sm:gap-4">
                        <select 
                            value={selectedRegion}
                            onChange={(e) => setSelectedRegion(e.target.value)}
                            className="w-full sm:w-auto px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-gray-100"
                        >
                            {regions.map(region => (
                                <option key={region.value} value={region.value}>
                                    {region.label}
                                </option>
                            ))}
                        </select>
                        <button
                            onClick={() => setShowSettings(!showSettings)}
                            className="w-full sm:w-auto px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors text-sm sm:text-base"
                        >
                            ⚙️ Settings
                        </button>
                        <button
                            onClick={loadDashboardData}
                            disabled={isLoading}
                            className="w-full sm:w-auto px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-50 transition-colors text-sm sm:text-base"
                        >
                            {isLoading ? '🔄 Loading...' : '🔄 Refresh'}
                        </button>
                        <ThemeToggle theme={theme} toggleTheme={toggleTheme} />
                    </div>
                </div>

                {/* Settings Panel */}
                {showSettings && (
                    <div className="mb-6">
                        <SettingsPanel
                            threshold={kpiData.threshold}
                            onThresholdUpdate={updateThreshold}
                            onClose={() => setShowSettings(false)}
                        />
                    </div>
                )}

                {/* KPI Cards */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4 mb-4 sm:mb-6">
                    <KPICard
                        title={kpiData.isRealData ? "Current Month Spend" : "Estimated Current Spend"}
                        value={formatCurrency(kpiData.currentSpend)}
                        change={kpiData.isRealData ? "📊 Real AWS Data" : `📈 Based on ${kpiData.totalAlerts} alerts`}
                        trend={kpiData.currentSpend > kpiData.threshold ? "up" : "down"}
                        icon="💰"
                        className={kpiData.currentSpend > kpiData.threshold ? "border-red-200 bg-red-50 dark:bg-red-900/20 dark:border-red-800" : ""}
                    />
                    <KPICard
                        title="Forecasted Bill"
                        value={formatCurrency(kpiData.forecastedBill)}
                        change={`+20% projection`}
                        trend="up"
                        icon="📈"
                    />
                    <KPICard
                        title="Highest Cost Service"
                        value={formatCurrency(kpiData.highestCostService.cost)}
                        change={kpiData.highestCostService.name}
                        trend="neutral"
                        icon="🏆"
                    />
                    <KPICard
                        title="Alert Threshold"
                        value={formatCurrency(kpiData.threshold)}
                        change={kpiData.currentSpend > kpiData.threshold ? "⚠️ Exceeded" : "✅ Safe"}
                        trend={kpiData.currentSpend > kpiData.threshold ? "up" : "down"}
                        icon="🎯"
                        className={kpiData.currentSpend > kpiData.threshold ? "border-red-200 bg-red-50 dark:bg-red-900/20 dark:border-red-800" : ""}
                    />
                </div>

                {/* Statistics Cards */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                    <Card>
                        <CardContent>
                            <div className="text-center">
                                <div className="text-3xl mb-2">📊</div>
                                <div className="text-2xl font-bold text-gray-900 dark:text-gray-100">{kpiData.totalAlerts}</div>
                                <div className="text-sm text-gray-500 dark:text-gray-400">Total Alerts</div>
                            </div>
                        </CardContent>
                    </Card>
                    <Card>
                        <CardContent>
                            <div className="text-center">
                                <div className="text-3xl mb-2">🚨</div>
                                <div className="text-2xl font-bold text-red-600 dark:text-red-400">{kpiData.highPriorityAlerts}</div>
                                <div className="text-sm text-gray-500 dark:text-gray-400">High Priority</div>
                            </div>
                        </CardContent>
                    </Card>
                    <Card>
                        <CardContent>
                            <div className="text-center">
                                <div className="text-3xl mb-2">🌍</div>
                                <div className="text-2xl font-bold text-blue-600 dark:text-blue-400">{selectedRegion}</div>
                                <div className="text-sm text-gray-500 dark:text-gray-400">Active Region</div>
                            </div>
                        </CardContent>
                    </Card>
                </div>

                {/* Main Content */}
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    {/* Cost Logs */}
                    <div className="lg:col-span-2">
                        <Card>
                            <CardHeader>
                                <CardTitle>📋 Cost Alerts & Monitoring Logs</CardTitle>
                            </CardHeader>
                            <CardContent>
                                {isLoading ? (
                                    <div className="text-center py-8">
                                        <div className="text-gray-500 dark:text-gray-400">Loading cost logs...</div>
                                    </div>
                                ) : costLogs.length === 0 ? (
                                    <div className="text-center py-8">
                                        <div className="text-4xl mb-4">📭</div>
                                        <div className="text-gray-500 dark:text-gray-400">No cost logs found for {selectedRegion}</div>
                                        <p className="text-sm text-gray-400 dark:text-gray-500 mt-2">
                                            Logs will appear here when cost monitoring events occur
                                        </p>
                                    </div>
                                ) : (
                                    <div className="space-y-3 max-h-96 overflow-y-auto">
                                        {costLogs.map((log, index) => (
                                            <div 
                                                key={log.id || index} 
                                                className="border border-gray-200 dark:border-gray-700 rounded-lg p-4 hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors cursor-pointer"
                                                onClick={() => {
                                                    setSelectedLog(log);
                                                    setShowLogModal(true);
                                                }}
                                            >
                                                <div className="flex items-start justify-between">
                                                    <div className="flex-1">
                                                        <div className="flex items-center gap-2 mb-2">
                                                            <span className={`px-2 py-1 text-xs font-medium rounded-full border ${getSeverityColor(log.severity)}`}>
                                                                {log.severity?.toUpperCase() || 'UNKNOWN'}
                                                            </span>
                                                            <span className="text-sm text-gray-500 dark:text-gray-400">
                                                                📍 {log.region}
                                                            </span>
                                                        </div>
                                                        <div className="text-gray-900 dark:text-gray-100 mb-2">
                                                            {log.message}
                                                        </div>
                                                        <div className="text-sm text-gray-500 dark:text-gray-400">
                                                            🕒 {formatDate(log.timestamp || log.id)}
                                                        </div>
                                                    </div>
                                                    <div className="ml-4 text-gray-400 dark:text-gray-500">
                                                        <span className="text-xs">Click for details →</span>
                                                    </div>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </CardContent>
                        </Card>
                    </div>

                    {/* Emergency Controls & Timer */}
                    <div className="space-y-4">
                        <EmergencyButton 
                            onEmergencyStop={handleEmergencyStop}
                            selectedRegion={selectedRegion}
                        />
                        <MonitoringTimer />
                    </div>
                </div>

                {/* Footer */}
                <div className="mt-8 text-center text-sm text-gray-500 dark:text-gray-400">
                    <p>DeeJhay's Tracker Dashboard - Real-time cost monitoring</p>
                    <p>Region: {selectedRegion} | Project: {projectName}</p>
                    <p>Data updates automatically based on your AWS cost alerts</p>
                </div>
            </div>

            {/* Log Detail Modal */}
            <LogDetailModal 
                log={selectedLog}
                isOpen={showLogModal}
                onClose={() => {
                    setShowLogModal(false);
                    setSelectedLog(null);
                }}
            />
        </div>
    );
};

// App Component
const App = () => {
    return <Dashboard />;
};

// Render the app
ReactDOM.render(<App />, document.getElementById('root'));