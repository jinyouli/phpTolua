<?php

require_once(__DIR__ . '/Authenticator.Crypto.php');

class AuthException extends Exception
{

}

class AuthenticatorException extends AuthException
{

}

class DataAuthenticatorException extends AuthException
{

}

class ServerDownAuthenticatorException extends AuthException
{

    public $content;

    public function __construct($message, $content = null, $code = 0, Exception $previous = NULL)
    {
        parent::__construct($message, $code, $previous);
        $this->content = $content;
    }

}


class Authenticator
{
    // <editor-fold defaultstate="collapsed" desc="初始化URL变量">

    /**
     * @字符串，服务器地址
     */
    static private $server = '%s.mobile-service.blizzard.com';

    /**
     * @字符串，请求编号URL
     */
    static private $initialize_uri = "/enrollment/enroll.htm";

    /**
     * @字符串，请求时间URL
     */
    static private $synchronize_uri = "/enrollment/time.htm";

    /**
     * @字符串，通过恢复码恢复设备URL
     */
    static private $restore_uri = "/enrollment/initiatePaperRestore.htm";

    /**
     * @字符串，验证设备恢复URL
     */
    static private $restore_validate_uri = "/enrollment/validatePaperRestore.htm";

    /**
     * @指针数组，地址
     */
    static private $accepted_region = array('EU', 'US', 'CN', 'KR');

    /**
     * @整数，等待时间
     */
    static private $waitingtime = 30000;

    const GENERATE_SIZE = 45;
    const SYNC_SIZE = 8;
    const RESTORE_CHALLENGE_SIZE = 32;
    const RESTORE_VALIDATE_SIZE = 20;

    // </editor-fold>
    // <editor-fold defaultstate="collapsed" desc="初始化安全令变量">

    /**
     * @字符串，2位，请求地域(US/EU/CN/KR)
     */
    private $region = null;

    /**
     * @整数，暴雪服务器与本机间的间隔时间(毫秒)
     */
    private $sync = null;

    /**
     * @字符串，生成的序列号'XX-YYYY-YYYY-YYYY'
     */
    private $serial = null;

    /**
     * @字符串，40字节的十六进制密钥
     */
    private $secret = null;

    // </editor-fold>
    // <editor-fold defaultstate="collapsed" desc="constructor函数 (private)">

    /**
     * 创建一个新的安全令，如果$secret参数是空，则确认要请求一个新的安全令，
     * 并设置指针参数的地域
     */
    private function __construct($serial, $region = null, $secret = null, $sync = null)
    {
        if (!is_null($serial)) {
            $this->set_serial($serial);
        }

        if (!is_null($region)) {
            $this->set_region($region);
        }

        
        if (!is_null($secret)) {
            $this->set_secret($secret);
        }
        if (!is_null($sync)) {
            $this->set_sync($sync);
        }

        
    }

    // </editor-fold>
    // <editor-fold defaultstate="collapsed" desc="Authenticator 库">

    /**
     * 由给的$region参数快速生成一个安全令.
     * @传入 2位字符串代表地域US/EU/CN/KR.
     * @返回 生成的安全令
     */
    static public function generate($region)
    {
        $authenticator = new Authenticator(null, $region);
        $authenticator->initialize();
        return $authenticator;
    }

    /**
     * 通过序列号和密码生成安全令
     * @传入 序列号
     * @传入 解密密码
     * @返回 一枚安全令类
     */
    static public function restore($serial, $restore_code)
    {
        $authenticator = new Authenticator($serial);
        $authenticator->do_restore($restore_code);
        return $authenticator;
    }

    /**
     * 由所给信息生成一枚新的安全令
     * (@参见 serial(), @参见 secret())
     * @传入 序列号.
     * @传入 密钥.
     * @传入 同步时间(可选，尽量别选)
     * @返回 一枚新的安全令类
     */
    static public function factory($serial, $secret, $sync = null)
    {
        return new Authenticator($serial, null, substr($secret, 0, 40), $sync);
    }

    // </editor-fold>
    // <editor-fold defaultstate="collapsed" desc="公用获取">

    /**
     * 验证是否包含参数地区
     * @返回 字符串地域
     */
    public function region()
    {
        if (is_null($this->region))
            throw new DataAuthenticatorException('必须选择地区');
        if (!in_array($this->region, self::$accepted_region))
            $this->region = "US";
        return $this->region;
    }

    /**
     * 通过计算同步时间生成的服务器时间
     * @返回 整数，服务器时间，毫秒
     */
    public function servertime()
    {
        if (is_null($this->sync))
            $this->synchronize();
        return (int)(microtime(true) * 1000) + $this->sync;
    }

    /**
     * 每个KEY的环回时间
     * @返回 环回时间，单位毫秒
     */
    public function waitingtime()
    {
        return self::$waitingtime;
    }

    /**
     * 计算等待时间并返回
     * @返回 剩余等待时间
     */
    public function sleeptime()
    {
        $sleeptimetmp = (int)($this->servertime() / $this->waitingtime());
        $sleeptimetmp = $this->servertime() - $sleeptimetmp * $this->waitingtime();
        return $sleeptimetmp;
    }

    /**
     * 序列号格式如下，XX为地域，Y为数字
     * 'XX-YYYY-YYYY-YYYY'
     * @return 返回序列号
     * @throws DataAuthenticatorException
     */
    public function serial()
    {
        if (is_null($this->serial))
            throw new DataAuthenticatorException('Unable to find a valid serial');
        return $this->serial;
    }

    /**
     * 将安全令转换为如下格式'XXYYYYYYYYYYYY'XX为地域，Y为数字
     * @返回 转换后的序列号
     */
    public function plain_serial()
    {
        return strtoupper(str_replace('-', '', $this->serial()));
    }

    /**
     * 40位长度安全令密钥
     * @返回 密钥字节
     */
    public function secret()
    {
        if (is_null($this->secret))
            throw new DataAuthenticatorException('未找到密钥');
        return $this->secret;
    }

    /**
     * 生成10位还原密码以供其他设备使用.
     * @返回 还原密码
     */
    public function restore_code()
    {
        $serial = $this->plain_serial();
        $secret = pack('H*', $this->secret());
        // take the 10 last bytes of the digest of our data
        $data = substr(sha1($serial . $secret, true), -10);
        return Authenticator_Crypto::restore_code_to_char($data);
    }

    // </editor-fold>
    // <editor-fold defaultstate="collapsed" desc="公用设置">

    /**
     * 由战网时间设置安全令的同步时间
     * @传入 战网服务器与客户端的时差，单位毫秒
     */
    public function set_sync($sync)
    {
        $this->sync = $sync;
    }

    // </editor-fold>
    // <editor-fold defaultstate="collapsed" desc="处理生成安全令信息">

    /**
     * 由接收到的服务器时间计算同步差值.
     * 计算差值然后调用函数set_sync().
     * @传入 二进制服务器时间
     */
    private function _set_sync($server_time)
    {
        $time = time();
        $date = date('Y-m-d H:i:s', $time);

        $server_time = hexdec(bin2hex($server_time));   //服务器时间十进制
        $current_time = (int)(microtime(true) * 1000); //本机时间十进制
        $this->set_sync($server_time - $current_time);  //设置同步差值
    }

    /**
     * 设置序列号及地域
     * @传入 序列号，格式 'XX-YYYY-YYYY-YYYY'
     */
    private function set_serial($serial)
    {                                 //设置序列号
        $this->set_region(substr($serial, 0, 2));
        $this->serial = $serial;
    }

    private function set_region($region)
    {                                 //设置地域
        $region = 'CN';                                  //转换为大写
        if (!in_array($region, self::$accepted_region))                 //检测是否为EU/US/CN
            throw new DataAuthenticatorException('非法的地区设置 : ' . $region . '.');
        $this->region = $region;
    }

    /**
     * 设置密钥. 转换数据为十六进制后调用函数set_secret().
     * @传入 由服务器获取的二进制字符串$secret
     */
    private function _set_secret($secret)
    {
        $this->set_secret(bin2hex($secret));
    }

    /**
     * 设置密钥
     * @传入 字符串 40位密钥
     */
    private function set_secret($secret)
    {
        $this->secret = $secret;
    }

    /**
     * 返回基于选择地域所产生的服务器主机地址,最新地址已经更改了
     * @返回 服务器主机地址
     */
    private function server()
    {
        switch (strtolower($this->region())) {
            case "cn":
                // return "https://mobile-service.battlenet.com.cn";
                return "https://www.battlenet.com.cn";
            case "us":
                return "http://us.mobile-service.blizzard.com";
            case "eu":
                return "http://eu.mobile-service.blizzard.com";
            case "kr":
                return "http://kr.mobile-service.blizzard.com";
        }
        return sprintf(self::$server, strtolower($this->region()));
    }

    /**
     * 返回基于选择地域所产生的服务器主机地址,最新地址已经更改了
     * @返回 服务器主机地址
     * @param $region
     * @return string
     */
    public static function getServerFromRegion($region)
    {
        switch (strtolower($region)) {
            case "cn":
                // return "https://mobile-service.battlenet.com.cn";
                return "https://www.battlenet.com.cn";
            case "us":
                return "http://us.mobile-service.blizzard.com";
            case "eu":
                return "http://eu.mobile-service.blizzard.com";
            case "kr":
                return "http://kr.mobile-service.blizzard.com";
        }
        return sprintf(self::$server, strtolower($region));
    }
    // </editor-fold>
    // <editor-fold defaultstate="collapsed" desc="与服务器交互通讯">


    /**
     * 发送数据给服务器并返回相应数据
     * @传入 字符串域名，响应数据大小
     * @传入 数据，可为控
     * @返回 截取的返回信息
     */
    private function send($uri, $response_size, $data = null)
    {
        $ch = curl_init();
        $url = $this->server() . $uri;
        $header = array(
            'Content-Type: application/octet-stream',
            'Connection: close'
        );

        curl_setopt($ch, CURLOPT_HEADER, 0);
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $header);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        if (!is_null($data)) {
            curl_setopt($ch, CURLOPT_POST, 1);
            curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
        }
        $errNo = curl_errno($ch);
        $result = curl_exec($ch);


		return $result;
    }

    private function create_key($size)
    {
        return substr(sha1(rand()), 0, $size);                          //sha1运算随机生成数字后截取指定数量的字节
    }

    /**
     * 初始化一个新的安全令.
     */
    private function initialize()
    {
        $f_code = chr(1);
        $enc_key = $this->create_key(37);
        $model = str_pad('ALPC_IPHONE7PLUS_OLAUTH', 16, chr(0), STR_PAD_RIGHT);   //截取16位，不足用0补齐

        $data = $f_code . $enc_key . $this->region() . $model;                //0:1,1-37:37位随机密钥,38-39:US/EU/CN/KR,40-55:16位设备信息

        $response = $this->send(self::$initialize_uri, self::GENERATE_SIZE, $this->encrypt($data)); //将56位数据通过RSA-1024加密后发送，并返回信息

        $data = $this->decrypt(substr($response, 8), $enc_key);         //解密接收到的返回信息
        $this->_set_sync(substr($response, 0, 8));                      //设置同步时间差
        $this->_set_secret(substr($data, 0, 20));                       //设置密钥
        $this->set_serial(substr($data, 20));                           //设置序列号
    }

    /*
     * 回复一枚安全令，使用给予的序列号和解密密码
     * @传入 解密密码
     */

    private function do_restore($restore_code)
    {
        $serial = $this->plain_serial();       
        
        //无横线的序列号格式
        $challenge = $this->send(self::$restore_uri, self::RESTORE_CHALLENGE_SIZE, $serial);
        $restore_code = Authenticator_Crypto::restore_code_from_char(strtoupper($restore_code));

        $serialStr = $serial . $challenge;
        $mac = hash_hmac('sha1', $serialStr, $restore_code, true);
        $enc_key = $this->create_key(20);
        $data = $serial . $this->encrypt($mac . $enc_key);

        $response = $this->send(self::$restore_validate_uri, self::RESTORE_VALIDATE_SIZE, $data);
        
        $ret = empty($response);
        if(!$ret){
            $data = $this->decrypt($response, $enc_key);
            $this->_set_secret($data);
            $this->synchronize(); 
        }else{
            $this->secret = "0";
        }
        
    }

    /**
     * 通过HTTP请求获取服务器时间，并重新设置同步时差
     */
    private function synchronize()
    {
        $response = $this->send(self::$synchronize_uri, self::SYNC_SIZE);
        $this->_set_sync($response);
    }

    // </editor-fold>
    // <editor-fold defaultstate="collapsed" desc="数据处理，加解密，生成编码">

    /**
     * 加密数据
     * @传入 想要加密的数据
     * @返回 加密后的数据
     */
    private function encrypt($data)
    {
        return Authenticator_Crypto::encrypt($data);
    }

    /**
     * 解密从服务器获得的数据，使用主机生成的KEY
     * @传入 数据
     * @传入 密钥
     * @返回 解密后的数据
     */
    private function decrypt($data, $key)
    {
        return Authenticator_Crypto::decrypt($data, $key);
    }

    public function getsync()
    {
        if (is_null($this->sync))
            $this->synchronize();
        return $this->sync;
    }

    function strigToBinary($string)
    {
        $characters = str_split($string);
        $binary = [];
        foreach ($characters as $character) {
            $data = unpack('H*', $character);
            $binary[] = base_convert($data[1], 16, 2);
        }
    
        return implode(' ', $binary);    
    }
    

    /**
     * 计算安全令显示码
     * @返回 8位长度的字符串(8位数字)
     */
    public function code()
    {
        // 转换密钥为二进制
        $secret = pack('H*', $this->secret());
        $current_time = (int)(microtime(true) * 1000);
        // 计算环回数
        $time = (int)($current_time / $this->waitingtime());
        // 转换为8位无符号长整型变量
        $cycle = pack('N*', 0, $time);
        // 计算由密钥和环回数生成的HMAC-SHA1加密数据
        $mac = hash_hmac('sha1', $cycle, $secret);
        // MAC的最后四位指向开始字节
        $start = hexdec($mac{39}) * 2;
        // 选择从开始字节开始的一共4字节
        $mac_part = substr($mac, $start, 8);
        $code = hexdec($mac_part) & 0x7fffffff;

        // 取最后八位，不足用0补齐
        return str_pad($code % 100000000, 8, '0', STR_PAD_LEFT);
    }

    // </editor-fold>
}
